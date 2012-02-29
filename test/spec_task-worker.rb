require 'innocent-white/test-util'
require 'innocent-white/agent/task-worker'
require 'innocent-white/document'

describe "TaskWorker" do
  before do
    @ts_server = create_remote_tuple_space_server
    # setup workers
    @worker1 = Agent[:task_worker].start(@ts_server)
    @worker2 = Agent[:task_worker].start(@ts_server)
    @worker3 = Agent[:task_worker].start(@ts_server)
    # make a task
    @task1 = Tuple[:task].new(rule_path: "test", inputs: ["1.a"], params: [])
    # make a rule
    doc = InnocentWhite::Document.new do
      action("test") do
        inputs  '*.a'
        outputs '{$INPUT[1].MATCH[1]}.b'
        content 'echo -n "input: {$INPUT[1].VALUE}"'
      end
    end
    write(Tuple[:rule].new(rule_path: "test", content: doc["test"], status: :known))
    # workers are waiting tasks
    @worker1.wait_till(:task_waiting, 1)
    @worker2.wait_till(:task_waiting, 1)
    @worker3.wait_till(:task_waiting, 1)
  end

  it "should wait tasks" do
    @worker1.current_state.should == :task_waiting
    @worker2.current_state.should == :task_waiting
    @worker3.current_state.should == :task_waiting
    check_exceptions
  end

  it "should say hello and bye" do
    # check hello message
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
    # check bye message
    agents = read_all(Tuple[:agent].any)
    agents.should.not.include @worker1.to_agent_tuple
    agents.should.not.include @worker2.to_agent_tuple
    agents.should.not.include @worker3.to_agent_tuple
    @ts_server.current_task_worker_size.should == 0
    check_exceptions
  end

  it "should process tasks" do
    # terminate worker2,3
    @worker2.terminate
    @worker3.terminate
    @worker2.wait_till(:terminated)
    @worker3.wait_till(:terminated)
    @worker1.current_state.should == :task_waiting
    @worker2.current_state.should == :terminated
    @worker3.current_state.should == :terminated

    nf = get_tuple_space_server.notify(nil, Tuple[:task].any.to_tuple_space_form)
    Thread.new do
      nf.each do |event, tuple|
        puts '---------------event---------------------'
        p event
        p tuple
        p @worker1.current_state
      end
    end

    # push task
    @worker1.wait_until_count(1, :task_finishing, 3) do
      write(@task1)
    end
    p @ts_server.all_tuples
    # process task
    observe_exceptions do
      sleep 0.3
      # check finished tuple
      finished = read(Tuple[:finished].any)
      finished.task_id.should == @task1.task_id
      # check result data
      req_data = Tuple[:data].any
      req_data.name = "1.b"
      data = read(req_data)
      Resource[data.uri].should == "input: 1.a"
    end
  end
end
