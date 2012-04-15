# -*- coding: utf-8 -*-

require 'innocent-white/test-util'
require 'parslet/convenience'

describe 'Document' do
  before do
    @parser = Document::Parser.new
    @transform = Document::Transformer.new
  end

  it 'should get a package line' do
    line = 'package abc'
    package = @transform.apply(@parser.package_line.parse(line))
    package.name.should == 'abc'
  end

  it 'should get a data name' do
    text = "'test.a'"
    data = @transform.apply(@parser.expr.parse(text))
    data.name.should == "test.a"
  end

  it 'should get a data name include a single quote' do
    text = "'test\\'.a'"
    data = @transform.apply(@parser.expr.parse(text))
    data.name.should == "test\'.a"
  end

  it 'should get input line' do
    line = "input 'test.a'"
    input = @transform.apply(@parser.input_line.parse(line))
    input.name.should == "test.a"
    input.should.each
    input.exceptions.should.empty
  end

  it 'should get input line with an exception' do
    line = "input '*.a'.except('test.a')"
    input = @transform.apply(@parser.input_line.parse(line))
    input.name.should == "*.a"
    input.should.each
    input.exceptions.should == [DataExpr.new("test.a")]
  end

  it 'should get input line with exceptions' do
    line = "input '*.a'.except('test.a', 'test.b')"
    input = @transform.apply(@parser.input_line.parse(line))
    input.exceptions.should == [DataExpr.new("test.a"), DataExpr.new("test.b")]
  end

  it 'should get input line with all modifier' do
    line = "input-all '*.a'"
    input = @transform.apply(@parser.input_line.parse(line))
    input.name.should == "*.a"
    input.should.all
    input.exceptions.should.empty
  end

  it 'should get output line' do
    line = "output 'test.a'"
    output = @transform.apply(@parser.output_line.parse(line))
    output.name.should == "test.a"
    output.should.each
    output.exceptions.should.empty
  end

  it 'should get output line with an exception' do
    line = "output '*.a'.except('test.a')"
    output = @transform.apply(@parser.output_line.parse(line))
    output.name.should == "*.a"
    output.should.each
    output.exceptions.should == [DataExpr.new("test.a")]
  end

  it 'should get output line with exceptions' do
    line = "output '*.a'.except('test.a', 'test.b')"
    output = @transform.apply(@parser.output_line.parse(line))
    output.exceptions.should == [DataExpr.new("test.a"), DataExpr.new("test.b")]
  end

  it 'should get output line with all modifier' do
    line = "output-all '*.a'"
    output = @transform.apply(@parser.output_line.parse(line))
    output.name.should == "*.a"
    output.should.all
    output.exceptions.should.empty
  end

  it 'should get param line' do
    line = "param $ABC"
    param = @transform.apply(@parser.param_line.parse(line))
    param.should == "ABC"
  end

  it 'should get param line with Japanese' do
    line = "param $あいうえお"
    param = @transform.apply(@parser.param_line.parse(line))
    param.should == "あいうえお"
  end

  it 'should get a call rule element' do
    line = "rule TestA"
    elt = @transform.apply(@parser.call_rule_line.parse(line))
    elt.should.kind_of(Rule::FlowElement::CallRule)
    elt.rule_path.should == "TestA"
    elt.should.not.sync_mode
  end

  it 'should get a call rule element with sync mode' do
    line = "rule TestA.sync"
    elt = @transform.apply(@parser.call_rule_line.parse(line))
    elt.should.sync_mode
  end

  it 'should get flow elements' do
    lines = <<-BLOCK
Flow---
rule TestA
rule TestB
---End
BLOCK
    block = @transform.apply(@parser.flow_block.parse(lines))[:flow_block]
    elt1 = block[0]
    elt1.should.kind_of(Rule::FlowElement::CallRule)
    elt1.rule_path.should == "TestA"
    elt2 = block[1]
    elt2.should.kind_of(Rule::FlowElement::CallRule)
    elt2.rule_path.should == "TestB"
  end

  it 'should get a condition element' do
    lines = <<BLOCK
if ({$TEST})
  rule TestA
end
BLOCK
    elt = @transform.apply(@parser.if_block.parse(lines))
    elt.should.kind_of(Rule::FlowElement::Condition)
    elt.block(true).size.should == 1
    elt.block(true).first.should.kind_of(Rule::FlowElement::CallRule)
    elt.block(true).first.rule_path.should == "TestA"
    elt.block(false).size.should == 0
  end

  it 'should get a condition element with an else block' do
    lines = <<BLOCK
if ({$TEST})
  rule TestA
else
  rule TestB
end
BLOCK
    elt = @transform.apply(@parser.if_block.parse(lines))
    elt.should.kind_of(Rule::FlowElement::Condition)
    elt.block(true).size.should == 1
    elt.block(true).first.should.kind_of(Rule::FlowElement::CallRule)
    elt.block(true).first.rule_path.should == "TestA"
    elt.block(false).size.should == 1
    elt.block(false).first.should.kind_of(Rule::FlowElement::CallRule)
    elt.block(false).first.rule_path.should == "TestB"
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
    block = @transform.apply(@parser.flow_block.parse(lines))[:flow_block]
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
    elt = @transform.apply(@parser.case_block.parse(lines))
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
    elt = @transform.apply(@parser.call_rule_line.parse(line))
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
    action = @transform.apply(@parser.parse(document)).first
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
    result = @transform.apply(@parser.parse(document)).first
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
    actions = @transform.apply(@parser.parse(document))
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
    result = @transform.apply(@parser.parse(document)).first
    result.should.kind_of(Rule::FlowRule)
    result.inputs.size.should == 1
    result.outputs.size.should == 1
    result.params.should == ["ConvertCharSet"]
    result.content.size.should == 3
  end
end
