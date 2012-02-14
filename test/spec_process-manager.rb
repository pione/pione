require 'innocent-white/process-handler'
require 'innocent-white/agent/process-manager'
require 'innocent-white/simulator/input-generator'

include InnocentWhite

Thread.abort_on_exception = true

describe "ProcessManager" do
  before do
    @ts_server = TupleSpaceServer.new(task_worker_resource: 3)
    @generator = Agent[:input_generator].new(@ts_server, 1..10, "a")
    document = {"/main" => ProcessHandler::Action.define(inputs: [/(.*).a/],
                                                        outputs: ["{$1}.a"],
                                                        content: "echo 'abc' > {$OUTPUT}")}
    @manager = Agent[:process_manager].new(@ts_server, document)
  end
  
  it "should make tasks" do
    sleep 0.1
    @ts_server.count_tuple(Tuple[:task].any).should == 10
  end

end

