require 'innocent-white/util'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'
require 'innocent-white/agent/task-worker'

include InnocentWhite

describe "TupleSpaceServer" do
  before do
    @ts_server = TupleSpaceServer.new(worker_resource: 3)
    @worker1 = Agent[:task_worker].new(@ts_server)
    @worker2 = Agent[:task_worker].new(@ts_server)
    @worker3 = Agent[:task_worker].new(@ts_server)
  end

  it "should announce that the worker go into the tuple space server" do
    @ts_server.current_task_worker_size.should == 3
  end

  it "should work" do
    @ts_server.write(Tuple[:task])
    @ts_server.task_worker_resource.should == 4
  end

end
