require 'innocent-white/util'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'

include InnocentWhite

describe "TupleSpaceServer" do
  before do
    @ts_server = TupleSpaceServer.new(task_worker_resource: 4)
  end

  it "should count worker" do
    @ts_server.current_task_worker_size.should == 0
    t1 = Tuple[:agent].new(agent_type: :task_worker, agent_id: Util.uuid)
    @ts_server.write(t1)
    @ts_server.current_task_worker_size.should == 1
    t2 = Tuple[:agent].new(agent_type: :task_worker, agent_id: Util.uuid)
    @ts_server.write(t2)
    @ts_server.current_task_worker_size.should == 2
    t3 = Tuple[:agent].new(agent_type: :task_worker, agent_id: Util.uuid)
    @ts_server.write(t3)
    @ts_server.current_task_worker_size.should == 3
    @ts_server.take(t1)
    @ts_server.current_task_worker_size.should == 2
    @ts_server.take(t2)
    @ts_server.current_task_worker_size.should == 1
    @ts_server.take(t3)
    @ts_server.current_task_worker_size.should == 0
  end

  it "should know worker resource" do
    @ts_server.task_worker_resource.should.== 4
  end

end
