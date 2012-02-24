require 'innocent-white/test-util'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'
require 'innocent-white/agent/task-worker'
require 'innocent-white/document'

include InnocentWhite

describe "TaskWorker" do
  before do
    @remote_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3))
    @ts_server = DRbObject.new(nil, @remote_server.uri)
    @worker1 = Agent[:task_worker].new(@ts_server)
    @worker2 = Agent[:task_worker].new(@ts_server)
    @worker3 = Agent[:task_worker].new(@ts_server)
    @task1 = Tuple[:task].new(module_path: "/test1", inputs: ["1.a"], outputs: ["1.b"], uuid: Util.uuid)
    doc = InnocentWhite::Document.new do
      action("test") do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content 'echo -n "input: {$INPUT[1].VALUE}"'
      end
    end
    @ts_server.write(Tuple[:rule].new(path: "/test", content: doc["test"], status: :known))
  end

  it "should wait tasks" do
    sleep 0.1
    @worker1.should.be.task_waiting
    @worker2.should.be.task_waiting
    @worker3.should.be.task_waiting
    check_exceptions(@ts_server)
  end

  it "should say hello and bye" do
    @worker1.wait_till(:task_waiting)
    @worker2.wait_till(:task_waiting)
    @worker3.wait_till(:task_waiting)
    agents = @ts_server.read_all(Tuple[:agent].any)
    agents.should.include @worker1.to_agent_tuple
    agents.should.include @worker2.to_agent_tuple
    agents.should.include @worker3.to_agent_tuple
    @ts_server.current_task_worker_size.should == 3
    @worker1.terminate
    @worker2.terminate
    @worker3.terminate
    @worker1.wait_till(:terminated)
    @worker2.wait_till(:terminated)
    @worker3.wait_till(:terminated)
    agents = @ts_server.read_all(Tuple[:agent].any)
    agents.should.not.include @worker1.to_agent_tuple
    agents.should.not.include @worker2.to_agent_tuple
    agents.should.not.include @worker3.to_agent_tuple
    @ts_server.current_task_worker_size.should == 0
    check_exceptions(@ts_server)
  end

  it "should process tasks" do
    @ts_server.write(@task1)
    sleep 0.1
    @ts_server.count_tuple(Tuple[:task].any).should == 0
    sleep 0.1
    check_exceptions(@ts_server)
    finished = @ts_server.read_all(Tuple[:finished].any)
    finished.size.should == 1
    finished.first.to_tuple.task_id.should == @task1.task_id
    req_data = Tuple[:data].any
    req_data.name = "1.b"
    data = @ts_server.read(req_data).to_tuple
    data.raw.should == "input: 1.a"
  end
end
