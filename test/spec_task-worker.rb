require 'innocent-white/test-util'
require 'innocent-white/agent/task-worker'
require 'innocent-white/document'

describe "TaskWorker" do
  before do
    @ts_server = create_remote_tuple_space_server
    @worker1 = Agent[:task_worker].new(@ts_server)
    @worker2 = Agent[:task_worker].new(@ts_server)
    @worker3 = Agent[:task_worker].new(@ts_server)
    @task1 = Tuple[:task].new(rule_path: "test", inputs: ["1.a"], outputs: ["1.b"], params: [])
    doc = InnocentWhite::Document.new do
      action("test") do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content 'echo -n "input: {$INPUT[1].VALUE}"'
      end
    end
    @ts_server.write(Tuple[:rule].new(rule_path: "test", content: doc["test"], status: :known))
  end

  it "should wait tasks" do
    @worker1.wait_till(:task_waiting, 1)
    @worker2.wait_till(:task_waiting, 1)
    @worker3.wait_till(:task_waiting, 1)
    check_exceptions
  end

  it "should say hello and bye" do
    @worker1.wait_till(:task_waiting)
    @worker2.wait_till(:task_waiting)
    @worker3.wait_till(:task_waiting)
    agents = read_all(Tuple[:agent].any)
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
    agents = read_all(Tuple[:agent].any)
    agents.should.not.include @worker1.to_agent_tuple
    agents.should.not.include @worker2.to_agent_tuple
    agents.should.not.include @worker3.to_agent_tuple
    @ts_server.current_task_worker_size.should == 0
    check_exceptions
  end

  it "should process tasks" do
    write_and_wait_to_be_taken(@task1)
    observe_exceptions do
      sleep 0.3
      p @worker1
      p @worker2
      p @worker3
      p @ts_server.all_tuples
      finished = read(Tuple[:finished].any)
      finished.task_id.should == @task1.task_id
      req_data = Tuple[:data].any
      req_data.name = "1.b"
      data = read(req_data)
      Resource[data.uri].should == "input: 1.a"
    end
  end
end
