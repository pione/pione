require 'innocent-white/agent/module-provider'

include InnocentWhite

Thread.abort_on_exception = true

describe "ModuleProvider" do
  before do
    @ts_server = TupleSpaceServer.new(task_worker_resource: 3)
    @provider = Agent[:module_provider].new(@ts_server)
    @action_a = ProcessHandler::Action.define(inputs: [], outputs: [], content: "echo 'abc'")
    @action_b = ProcessHandler::Action.define(inputs: [], outputs: [], content: "echo 'XYZ'")
    @provider.add_module("/a", @action_a)
    @provider.add_module("/a/b", @action_b)
  end

  it "should provide known module information" do
    @ts_server.write(Tuple[:request_module].new(path: "/a"))
    tuple_a = nil
    should.not.raise(Rinda::RequestExpiredError) do
      tuple_a = @ts_server.read(Tuple[:module].new(path: "/a"),1).to_tuple
    end
    tuple_a.status.should == :known
    tuple_a.content.superclass.should == ProcessHandler::Action
    tuple_a.content.should == @action_a
    @ts_server.write(Tuple[:request_module].new(path: "/a/b"))
    tuple_b = nil
    should.not.raise(Rinda::RequestExpiredError) do
      tuple_b = @ts_server.read(Tuple[:module].new(path: "/a/b"),1).to_tuple
    end
    tuple_b.status.should == :known
    tuple_b.content.superclass.should == ProcessHandler::Action
    tuple_b.content.should == @action_b
  end
  
  it "should provide unknown module information" do
    @ts_server.write(Tuple[:request_module].new(path: "/b"))
    tuple = nil
    should.not.raise(Rinda::RequestExpiredError) do
      tuple = @ts_server.read(Tuple[:module].new(path: "/b"),1).to_tuple
    end
    tuple.status.should == :unknown
  end
end
