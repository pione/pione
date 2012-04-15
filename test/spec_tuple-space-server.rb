require 'innocent-white/test-util'

describe "TupleSpaceServer" do
  before do
    @server = TupleSpaceServer.new
  end

  it "should create be alive" do
    @server.should.alive
  end

  it "should count tuple size" do
    Tuple.define_format [:test, :sym]
    @server.write([:test, :a])
    @server.count_tuple([:test, nil]).should == 1
    @server.write([:test, :b])
    @server.count_tuple([:test, nil]).should == 2
    Tuple.delete_format(:test)
  end

  it "should count worker" do
    @server.current_task_worker_size.should == 0
    t1 = Tuple[:agent].new(agent_type: :task_worker, uuid: Util.uuid)
    @server.write(t1)
    @server.current_task_worker_size.should == 1
    t2 = Tuple[:agent].new(agent_type: :task_worker, uuid: Util.uuid)
    @server.write(t2)
    @server.current_task_worker_size.should == 2
    t3 = Tuple[:agent].new(agent_type: :task_worker, uuid: Util.uuid)
    @server.write(t3)
    @server.current_task_worker_size.should == 3
    @server.take(t1)
    @server.current_task_worker_size.should == 2
    @server.take(t2)
    @server.current_task_worker_size.should == 1
    @server.take(t3)
    @server.current_task_worker_size.should == 0
  end

  it "should know worker resource" do
    @server.task_worker_resource.should.== 4
  end
end
