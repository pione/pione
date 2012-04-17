# -*- coding: utf-8 -*-

require 'innocent-white/test-util'

describe 'Document::Transformer' do
  before do
    @parser = Document::Parser.new
    @transformer = Document::Transformer.new
  end

  describe 'data_expr' do
    it 'should include a single quote' do
      text = "'test\\'.a'"
      data_expr = @transformer.apply(@parser.data_expr.parse(text))
      data_expr.should.kind_of(DataExpr)
      data_expr.name.should == "test\'.a"
    end

    it 'should have an exception' do
      line = "'*.a'.except('test.a')"
      data_expr = @transformer.apply(@parser.data_expr.parse(line))
      data_expr.name.should == "*.a"
      data_expr.exceptions.should == [DataExpr.new("test.a")]
    end

    it 'should have exceptions' do
      line = "'*.a'.except('test.a', 'test.b')"
      data_expr = @transformer.apply(@parser.data_expr.parse(line))
      data_expr.exceptions.should == [DataExpr.new("test.a"), DataExpr.new("test.b")]
    end

    it 'should raise an error when referencing unknown attribution' do
      line = "'test.a'.unknown"
      should.raise(Document::UnknownAttribution) do
        @transformer.apply(@parser.data_expr.parse(line))
      end
    end
  end

  describe 'package_line' do
    it 'should get a package line' do
      line = 'package abc'
      package = @transformer.apply(@parser.package_line.parse(line))
      package.name.should == 'abc'
    end
  end

  describe 'input_line' do
    it 'should get input line' do
      line = "input 'test.a'"
      input = @transformer.apply(@parser.input_line.parse(line))
      input.name.should == "test.a"
      input.should.each
      input.exceptions.should.empty
    end

    it 'should get input line with all modifier' do
      line = "input-all '*.a'"
      input = @transformer.apply(@parser.input_line.parse(line))
      input.name.should == "*.a"
      input.should.all
      input.exceptions.should.empty
    end
  end

  describe 'output_line' do
    it 'should get output line' do
      line = "output 'test.a'"
      output = @transformer.apply(@parser.output_line.parse(line))
      output.name.should == "test.a"
      output.should.each
      output.exceptions.should.empty
    end

    it 'should get output line with all modifier' do
      line = "output-all '*.a'"
      output = @transformer.apply(@parser.output_line.parse(line))
      output.name.should == "*.a"
      output.should.all
      output.exceptions.should.empty
    end
  end

  describe 'param_line' do
    it 'should get param line' do
      line = "param $ABC"
      param = @transformer.apply(@parser.param_line.parse(line))
      param.should == "ABC"
    end

    it 'should get param line with Japanese' do
      line = "param $あいうえお"
      param = @transformer.apply(@parser.param_line.parse(line))
      param.should == "あいうえお"
    end
  end

  describe 'rule_call_line' do
    it 'should get a call rule element' do
      line = "rule TestA"
      rule_call = @transformer.apply(@parser.rule_call_line.parse(line))
      rule_call.should.kind_of(FlowElement::CallRule)
      rule_call.expr.name.should == "TestA"
    end

    it 'should get a call rule element with sync mode' do
      line = "rule TestA.sync"
      should.not.raise do
        @transformer.apply(@parser.rule_call_line.parse(line))
      end
    end
  end

  describe 'if_block' do
    it 'should get a condition element' do
      lines = <<-BLOCK
        if ($TEST)
          rule TestA
        end
      BLOCK
      cond = @transformer.apply(@parser.if_block.parse(lines))
      cond.should.kind_of(FlowElement::Condition)
      cond.blocks[true].size.should == 1
      cond.blocks[true].first.should.kind_of(FlowElement::CallRule)
      cond.blocks[true].first.expr.name.should == "TestA"
      cond.blocks[false].should == nil
    end

    it 'should get a condition element with an else block' do
      lines = <<-BLOCK
        if ($TEST)
          rule TestA
        else
          rule TestB
        end
      BLOCK
      elt = @transformer.apply(@parser.if_block.parse(lines))
      elt.should.kind_of(FlowElement::Condition)
      elt.blocks[true].size.should == 1
      elt.blocks[true].first.should.kind_of(FlowElement::CallRule)
      elt.blocks[true].first.expr.name.should == "TestA"
      elt.blocks[false].size.should == 1
      elt.blocks[false].first.should.kind_of(FlowElement::CallRule)
      elt.blocks[false].first.expr.name.should == "TestB"
    end
  end

  it 'should get flow elements' do
    lines = <<-BLOCK
Flow---
rule TestA
rule TestB
---End
BLOCK
    block = @transformer.apply(@parser.flow_block.parse(lines))[:flow_block]
    elt1 = block[0]
    elt1.should.kind_of(Rule::FlowElement::CallRule)
    elt1.rule_path.should == "TestA"
    elt2 = block[1]
    elt2.should.kind_of(Rule::FlowElement::CallRule)
    elt2.rule_path.should == "TestB"
  end


  it 'should get flow elements with condition' do
    lines = <<BLOCK
Flow---
if ({$TEST})
  rule TestA
end
rule TestB
---End
BLOCK
    block = @transformer.apply(@parser.flow_block.parse(lines))[:flow_block]
    elt = block[0]
    elt.should.kind_of(Rule::FlowElement::Condition)
    elt.block(true).size.should == 1
    elt.block(true).first.should.kind_of(Rule::FlowElement::CallRule)
    elt.block(true).first.rule_path.should == "TestA"
    elt.block(false).size.should == 0
    elt = block[1]
    elt.should.kind_of(Rule::FlowElement::CallRule)
    elt.rule_path.should == "TestB"
  end

  it 'should get a condition element from case block' do
    lines = <<BLOCK
case ({$TEST})
when "a"
  rule TestA
when "b"
  rule TestB
else
  rule TestOthers
end
BLOCK
    elt = @transformer.apply(@parser.case_block.parse(lines))
    elt.should.kind_of(Rule::FlowElement::Condition)
    elt.block("a").size.should == 1
    elt.block("a").first.should.kind_of(Rule::FlowElement::CallRule)
    elt.block("a").first.rule_path.should == "TestA"
    elt.block("b").size.should == 1
    elt.block("b").first.should.kind_of(Rule::FlowElement::CallRule)
    elt.block("b").first.rule_path.should == "TestB"
    elt.block("c").size.should == 1
    elt.block("c").first.should.kind_of(Rule::FlowElement::CallRule)
    elt.block("c").first.rule_path.should == "TestOthers"
  end

  it 'should get a call rule element with parameters' do
    line = 'rule Test.params("a", "b", "c")'
    elt = @transformer.apply(@parser.call_rule_line.parse(line))
    elt.should.kind_of(Rule::FlowElement::CallRule)
    elt.rule_path.should == "Test"
    elt.params.should == ["a", "b", "c"]
  end

  it 'should define action rule' do
    document = <<CODE
Rule Test
  input  '*.a'
  output '{$INPUT[1].MATCH[1]}.b'
Action---
echo "test" > {$OUTPUT[1].NAME}
---End
CODE
    action = @transformer.apply(@parser.parse(document)).first
    action.should.be.kind_of Rule::ActionRule
    action.inputs.should  == [ DataExpr['*.a'] ]
    action.outputs.should == [ DataExpr['{$INPUT[1].MATCH[1]}.b'] ]
    action.content.should == "echo \"test\" > {$OUTPUT[1].NAME}\n"
  end

  it 'should define flow rule' do
    document = <<CODE
Rule Test
  input '*.a'
  output '{$INPUT[1].MATCH[1]}.b'
Flow----
rule TestA
rule TestB.sync
----End
CODE
    result = @transformer.apply(@parser.parse(document)).first
    result.should.kind_of(Rule::FlowRule)
    result.inputs.should  == [ DataExpr['*.a'] ]
    result.outputs.should == [ DataExpr['{$INPUT[1].MATCH[1]}.b'] ]
  end

  it 'should get two action rules' do
    document = <<CODE
Rule TestA
  input  '*.a'
  output '{$INPUT[1].MATCH[1]}.b'
Action---
cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}
---End

Rule TestB
  input  '*.b'
  output '{$INPUT[1].MATCH[1]}.c'
Action---
cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}
---End
CODE
    actions = @transformer.apply(@parser.parse(document))
    actions.size.should == 2
    actions[0].should.be.kind_of Rule::ActionRule
    actions[0].path.should == "TestA"
    actions[1].should.be.kind_of Rule::ActionRule
    actions[1].path.should == "TestB"
  end

  it 'should read document' do
    document = <<CODE
Rule Main
  input-all '*.txt'.except('summary.txt')
  output 'summary.txt'
  param $ConvertCharSet
Flow---------------------------------------------------------------------------
if ({$ConvertCharset})
  rule NKF.params("-w")
end
rule CountChar.sync
rule Summarize
-----------------------------------------------------------------------------End
CODE
    result = @transformer.apply(@parser.parse(document)).first
    result.should.kind_of(Rule::FlowRule)
    result.inputs.size.should == 1
    result.outputs.size.should == 1
    result.params.should == ["ConvertCharSet"]
    result.content.size.should == 3
  end

end
