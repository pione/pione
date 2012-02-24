require 'innocent-white/test-util'
require 'innocent-white/data-name-exp'
require 'innocent-white/rule'
require 'innocent-white/document'
require 'innocent-white/agent/input-generator'

describe 'Rule' do
  describe 'ActionRule' do
    before do
      @ts_server = create_remote_tuple_space_server
      @gen1 = Agent[:input_generator].new_by_simple(@ts_server, "*.a", 1..10, 11..20)
      @gen2 = Agent[:input_generator].new_by_simple(@ts_server, "*.b", 1..10, 11..20)
      @rule = Document.new do
        action('test') do
          inputs  '*.a', '{$INPUT[1].MATCH[1]}.b'
          outputs '{$INPUT[1].MATCH[1]}.c'
          content 'expr {$INPUT[1].VALUE} + {$INPUT[2].VALUE}'
        end
      end['test']
    end

    it 'should find inputs and outputs' do
      @gen1.wait_till(:terminated)
      @gen2.wait_till(:terminated)
      check_exceptions(@ts_server)
      inputs = @rule.find_inputs(@ts_server, "/input")
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

