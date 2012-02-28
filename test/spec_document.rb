require 'innocent-white/test-util'

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
    action.inputs.should  == [ DataNameExp['*.a'] ]
    action.outputs.should == [ DataNameExp['{$INPUT[1].MATCH[1]}.b'] ]
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
    flow.inputs.should  == [ DataNameExp['*.a'] ]
    flow.outputs.should == [ DataNameExp['{$INPUT[1].MATCH[1]}.b'] ]
  end
end
