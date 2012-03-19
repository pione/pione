# -*- coding: utf-8 -*-
require 'innocent-white/test-util'
require 'parslet/convenience'

describe 'Document' do
  before do
    @parser = DocumentParser.new
    @transform = SyntaxTreeTransform.new
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
    input.exceptions.should == [DataExp.new("test.a")]
  end

  it 'should get input line with exceptions' do
    line = "input '*.a'.except('test.a', 'test.b')"
    input = @transform.apply(@parser.input_line.parse(line))
    input.exceptions.should == [DataExp.new("test.a"), DataExp.new("test.b")]
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
    output.exceptions.should == [DataExp.new("test.a")]
  end

  it 'should get output line with exceptions' do
    line = "output '*.a'.except('test.a', 'test.b')"
    output = @transform.apply(@parser.output_line.parse(line))
    output.exceptions.should == [DataExp.new("test.a"), DataExp.new("test.b")]
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

  it 'should get flow block' do
    lines = <<-BLOCK
Flow---
rule TestA
---End
BLOCK
    block = @transform.apply(@parser.flow_block.parse(lines))
    block.first.should.kind_of(Rule::FlowElement::CallRule)
    block.first.rule_path == "TestA"
    block.first.should.not.sync_mode
  end

  it 'should define action rule' do
    action = Document.new do
      action('test') do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content 'echo "test" > {$OUTPUT[1].NAME}'
      end
    end['test']
    action.should.be.kind_of Rule::ActionRule
    action.inputs.should  == [ DataExp['*.a'] ]
    action.outputs.should == [ DataExp['{$INPUT[1].MATCH[1]}.b'] ]
  end

  it 'should define flow rule' do
    flow = Document.new do
      flow('test') do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content [ call('test1'),
                  call('test2').with_sync]
      end
    end['test']
    flow.should.be.kind_of Rule::FlowRule
    flow.inputs.should  == [ DataExp['*.a'] ]
    flow.outputs.should == [ DataExp['{$INPUT[1].MATCH[1]}.b'] ]
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
    parser = DocumentParser.new
    parsed = begin
               parser.parse(document)
             rescue Parslet::ParseFailed => error
               puts error, parser.root.error_tree
             end
    result = SyntaxTreeTransform.new.apply(parsed)
    #p result
    #p SyntaxTreeTransform.new.apply({:name => 213, :x => 33})
  end
end
