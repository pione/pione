require 'innocent-white/test-util'
require 'parslet/convenience'

describe 'Document' do
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
if({$ConvertCharset}) {
  rule NKF.params("-w")
}
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
