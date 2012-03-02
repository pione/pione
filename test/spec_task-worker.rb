require 'innocent-white/test-util'
require 'innocent-white/agent/task-worker'

describe "TaskWorker" do
  before do
    @ts_server = create_remote_tuple_space_server

    # setup workers
    @worker1 = Agent[:task_worker].start(@ts_server)
    @worker2 = Agent[:task_worker].start(@ts_server)
    @worker3 = Agent[:task_worker].start(@ts_server)

    # make a task
    @uri = "local:/tmp/1.a"
    Resource[@uri].create "abc"
    @data = Tuple[:data].new(domain: 'test', name: "1.a", uri: @uri)
    @task1 = Tuple[:task].new(rule_path: "test", inputs: [@data], params: [])

    # make a rule
    doc = InnocentWhite::Document.new do
      action("test") do
        inputs  '*.a'
        outputs stdout('{$INPUT[1].MATCH[1]}.b')
        content 'echo -n "input: `cat {$INPUT[1]}`"'
      end
    end
    write(Tuple[:rule].new(rule_path: "test", content: doc["test"], status: :known))

    # workers are waiting tasks
    @worker1.wait_till(:task_waiting)
    @worker2.wait_till(:task_waiting)
    @worker3.wait_till(:task_waiting)
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

    # check state
    @worker1.current_state.should == :task_waiting
    @worker2.current_state.should == :terminated
    @worker3.current_state.should == :terminated

    # process info
    write(Tuple[:process_info].new('spec_task-worker', 'testid'))

    notifier = get_tuple_space_server.notify("take", Tuple[:task].any)
    Thread.new do
      notifier.each do |name, tuple|
        puts "#{name} >>> #{tuple}"
      end
    end

    # push task
    @worker1.wait_until_count(1, :task_finishing) do
      puts ">>> task waiting <<<"
      @worker1.wait_till(:task_waiting)
      puts ">>> write task <<<"
      write(@task1)
      sleep 1
      p @worker1
      check_exceptions
    end

    # process task
    observe_exceptions do
      sleep 0.3
      # check finished tuple
      finished = read(Tuple[:finished].any)
      #finished.task_id.should == @task1.task_id
      # check result data
      req_data = Tuple[:data].any
      req_data.name = "1.b"
      data = read(req_data)
      Resource[data.uri].read.should == "input: abc"
    end
  end
end
