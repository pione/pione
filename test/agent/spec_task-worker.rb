require_relative '../test-util'

describe 'Pione::Agent::TaskWorker' do
  describe 'transition' do
    before do
      DRb.start_service
      create_remote_tuple_space_server
      features = Feature::AndExpr.new(
        Feature::PossibleExpr.new('A'),
        Feature::PossibleExpr.new('B'),
        Feature::PossibleExpr.new('C')
      )
      @worker = Agent::TaskWorker.new(tuple_space_server, features)
    end

    after do
      tuple_space_server.terminate
    end

    it 'should take a task' do
      task = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature.empty,
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      write(task)
      @worker.__send__(:transit_to_initialized)
      @worker.__send__(:transit_to_task_waiting).should == task
    end

    it 'should wait taking a task because of features' do
      task = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature::RequisiteExpr.new('X'),
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      write(task)
      should.raise(Timeout::Error) do
        timeout(1) do
          @worker.__send__(:transit_to_task_waiting)
        end
      end
    end

    it 'should not wait taking a task because of features' do
      task = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature::RequisiteExpr.new('A'),
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      write(task)
      @worker.__send__(:transit_to_task_waiting).should == task
    end

    it 'should take a rule' do
      task1 = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature.empty,
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      rule = Tuple[:rule].new('&main:Test', :fake_content)
      write(rule)
      task2, result = @worker.__send__(:transit_to_rule_loading, task1)
      result.should == :fake_content
      task2.should == task1
    end

    it 'should raise an exception because a rule is unknown' do
      task = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature.empty,
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      rule = Tuple[:rule].new('&main:Test', :fake_content)
      write(rule)
      should.raise(Agent::TaskWorker::UnknownRuleError) do
        @worker.__send__(:transit_to_rule_loading, task)
      end
    end

    it 'should execute a task' do
      task1 = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature.empty,
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      write(Tuple[:working].new(task1.domain, "test"))
      rule = ActionRule.new(
        RuleExpr.new(Package.new('main'), 'Test'),
        RuleCondition.new(
          [],
          [DataExpr.new('out.txt')],
          Parameters.empty,
          Feature.empty,
          TicketExpr.empty,
          TicketExpr.empty
        ),
        ActionBlock.new("expr 1 + 2 > out.txt")
      )
      quiet_mode do
        task2, handler, result =
          @worker.__send__(:transit_to_task_executing, task1, rule)
        task2.should == task1
        result.first.name.should == "out.txt"
      end
    end

    it 'should write output data tuples' do
      task1 = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature.empty,
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      write(Tuple[:working].new(task1.domain, "test"))
      rule = FlowRule.new(
        RuleExpr.new(Package.new('main'), 'Test'),
        RuleCondition.new([], [], Parameters.empty, Feature.empty, TicketExpr.empty, TicketExpr.empty),
        :dummy
      )
      handler1 = RuleHandler::FlowHandler.new(
        tuple_space_server, rule, [], Parameters.empty, []
      )
      result = [Tuple[:data].new('&main:Test', '1.a', nil, Time.now)]
      task2, handler2 =
        @worker.__send__(:transit_to_data_outputing, task1, handler1, result)
      task2.should == task1
      handler2.should == handler1
      read(Tuple[:data].new(name: '1.a'))
    end

    it 'should write a finished_task tuple' do
      task = Tuple[:task].new(
        '&main:Test',
        [],
        Parameters.empty,
        Feature.empty,
        ID.domain_id("main", "Test", [], Parameters.empty),
        []
      )
      write(Tuple[:working].new(task.domain, "test"))
      rule = FlowRule.new(
        RuleExpr.new(Package.new('main'), 'Test'),
        RuleCondition.new([], [], Parameters.empty, Feature.empty, TicketExpr.empty, TicketExpr.empty),
        :dummy
      )
      handler = RuleHandler::FlowHandler.new(
        tuple_space_server, rule, [], Parameters.empty, []
      )
      @worker.__send__(:transit_to_task_finishing, task, handler)
      finished_task = read(Tuple[:finished].any)
      finished_task.domain.should == handler.domain
      finished_task.outputs.should == []
    end
  end

  describe 'running' do
    before do
      DRb.start_service
      create_remote_tuple_space_server

      Agent[:logger].start(tuple_space_server, Location["out.txt"])

      # process info
      write(Tuple[:process_info].new('spec_task-worker', 'testid'))

      # setup workers
      @worker1 = Agent[:task_worker].start(tuple_space_server)
      @worker2 = Agent[:task_worker].start(tuple_space_server)
      @worker3 = Agent[:task_worker].start(tuple_space_server)

      # make a task
      @location = Location[Temppath.create]
      @location.create "abc"
      @data = Tuple[:data].new(domain: 'test', name: "1.a", location: @location)
      @task1 = Tuple[:task].new(
        "&main:test",
        [@data],
        Parameters.empty,
        Feature.empty,
        ID.domain_id("main", "Test", [@data], Parameters.empty),
        []
      )

      # make a rule
      doc = Pione::Document.parse <<-DOCUMENT
        Rule test
          input  '*.a'
          output '{$*}.b'.stdout
        Action
        echo -n "input: `cat {$I[1]}`"
        End
      DOCUMENT
      write(
        Tuple[:rule].new(
          rule_path: "&main:test",
          content: doc["&main:test"]
        )
      )

      # workers are waiting tasks
      @worker1.wait_till(:task_waiting)
      @worker2.wait_till(:task_waiting)
      @worker3.wait_till(:task_waiting)
    end

    after do
      @worker1.terminate
      @worker2.terminate
      @worker3.terminate
      tuple_space_server.terminate
    end

    it "should wait tasks" do
      # check agent state
      @worker1.current_state.should == :task_waiting
      @worker2.current_state.should == :task_waiting
      @worker3.current_state.should == :task_waiting

      # check exceptions
      check_exceptions
    end

    it "should say hello and bye" do
      ## check hello message

      # check agent tuples
      agents = read_all(Tuple[:agent].any)
      agents.should.include @worker1.to_agent_tuple
      agents.should.include @worker2.to_agent_tuple
      agents.should.include @worker3.to_agent_tuple

      # check worker counter
      tuple_space_server.current_task_worker_size.should == 3

      # terminate workers
      @worker1.terminate
      @worker2.terminate
      @worker3.terminate

      # wait to terminate
      @worker1.wait_till(:terminated)
      @worker2.wait_till(:terminated)
      @worker3.wait_till(:terminated)

      ## check bye message

      # check agent tuples
      agents = read_all(Tuple[:agent].any)
      agents.should.not.include @worker1.to_agent_tuple
      agents.should.not.include @worker2.to_agent_tuple
      agents.should.not.include @worker3.to_agent_tuple

      # check agent counter
      tuple_space_server.current_task_worker_size.should == 0

      # check exceptions
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
      @worker2.running_thread.should.not.be.alive
      @worker3.running_thread.should.not.be.alive

      # process task on @worker1
      @worker1.wait_till(:task_waiting)
      write(@task1)

      # process task
      observe_exceptions do
        sleep 0.3
        # check finished tuple
        finished = read(Tuple[:finished].any)
        # check result data
        data = read(Tuple[:data].new(name: "1.b"))
        Resource[data.uri].read.should == "input: abc"
      end
    end
  end
end
