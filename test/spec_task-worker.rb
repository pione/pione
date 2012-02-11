require 'innocent-white/util'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'
require 'innocent-white/agent/task-worker'

include InnocentWhite

describe "TaskWorker" do
  before do
    @ts_server = TupleSpaceServer.new(task_worker_resource: 3)
    @worker1 = Agent[:task_worker].new(@ts_server)
    @worker2 = Agent[:task_worker].new(@ts_server)
    @worker3 = Agent[:task_worker].new(@ts_server)
    @task1 = Tuple[:task].new(name: :test1,
                              inputs: ["1.a"],
                              outputs: ["1.b"])
  end

  it "should announce that the worker go into the tuple space server" do
    tuple1 = @worker1.to_agent_tuple
    tuple1.should == Tuple[:agent].new(agent_type: :task_worker,
                                       agent_id: @worker1.agent_id)
    tuple2 = @worker2.to_agent_tuple
    tuple2.should == Tuple[:agent].new(agent_type: :task_worker,
                                       agent_id: @worker2.agent_id)
    tuple3 = @worker3.to_agent_tuple
    tuple3.should == Tuple[:agent].new(agent_type: :task_worker,
                                       agent_id: @worker3.agent_id)
    @ts_server.current_task_worker_size.should == 3
  end

  it "should work" do
    @ts_server.write(@task1)
    sleep 0.1
    @ts_server.count_tuple(Tuple[:task].any).should == 0
  end

end
