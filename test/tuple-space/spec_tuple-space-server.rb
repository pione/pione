require 'pione/test-helper'

TestHelper.scope do |this|
  class this::TestTuple < TupleSpace::BasicTuple
    define_format [:test_, :sym]
  end

  describe Pione::TupleSpace::TupleSpaceServer do
    before do
      @server = TupleSpaceServer.new({}, false)
    end

    after do
      @server.terminate
    end

    it "should create be alive" do
      @server.should.alive
    end

    it "should count tuple size" do
      @server.write(this::TestTuple.new(:a))
      @server.count_tuple(this::TestTuple.new).should == 1
      @server.write(this::TestTuple.new(:b))
      @server.count_tuple(this::TestTuple.new).should == 2
    end

    it "should count workers" do
      @server.current_task_worker_size.should == 0
      t1 = TupleSpace::AgentTuple.new(agent_type: :task_worker, uuid: Util::UUID.generate)
      @server.write(t1)
      @server.current_task_worker_size.should == 1
      t2 = TupleSpace::AgentTuple.new(agent_type: :task_worker, uuid: Util::UUID.generate)
      @server.write(t2)
      @server.current_task_worker_size.should == 2
      t3 = TupleSpace::AgentTuple.new(agent_type: :task_worker, uuid: Util::UUID.generate)
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
      @server.task_worker_resource.should == 1
    end
  end
end
