require 'innocent-white/test-util'
require 'innocent-white/data-name-exp'
require 'innocent-white/rule'
require 'innocent-white/document'
require 'innocent-white/agent/input-generator'

setup_test

describe 'Rule' do
  describe 'ActionRule' do
    before do
      @remote_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3))
      @ts_server = DRbObject.new(nil, @remote_server.uri)
      @gen1 = Agent[:input_generator].new_by_simple(@ts_server, "*.a", 1..10, 11..20)
      @gen2 = Agent[:input_generator].new_by_simple(@ts_server, "*.b", 1..10, 11..20)
      inputs = ['*.a', '{$INPUT[1].MATCH[1]}.b'].map(&DataNameExp)
      outputs = ['{$INPUT[1].MATCH[1]}.c'].map(&DataNameExp)
      @rule = Rule::ActionRule.new(inputs, outputs, [], "expr {$INPUT[1].VALUE} + {$INPUT[2].VALUE}")
    end

    it 'should find inputs and outputs' do
      @gen1.wait_till(:terminated)
      @gen2.wait_till(:terminated)
      inputs = @rule.find_inputs(@ts_server, "/")
      inputs.size.should == 10
      10.times do |i|
        a = @ts_server.read(Tuple[:data].new(name: "#{i+1}.a"))
        b = @ts_server.read(Tuple[:data].new(name: "#{i+1}.b"))
        inputs.should.include [a, b]
      end
    end
  end

  # before do
  #   @ts_server = TupleSpaceServer.new(task_worker_resource: 3)
  #   @generator = Agent[:input_generator].new(@ts_server, 1..10, "a")
  #   document = {"/main" => ProcessHandler::Action.define(inputs: [/(.*).a/],
  #                                                       outputs: ["{$1}.a"],
  #                                                       content: "echo 'abc' > {$OUTPUT}")}
  #   @manager = Agent[:process_manager].new(@ts_server, document)
  # end
  
  # it "should make tasks" do
  #   sleep 0.2
  #   @ts_server.count_tuple(Tuple[:task].any).should == 10
  # end

end

