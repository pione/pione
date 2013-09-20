require_relative '../test-util'

describe 'Pione::Agent::TaskWorker' do
  describe 'task acquisition' do
    before do
      @tuple_space = create_tuple_space_server

      @env = Lang::Environment.new.setup_new_package("TaskWorker")
      TestUtil::Lang.package_context!(@env, <<-PIONE)
        Rule R1
          output 'out'.touch
        End

        Rule R2
          output 'out'.touch
          feature +X
        End
      PIONE

      features = TestUtil::Lang.expr!(@env, "^A & ^B & ^C")
      @worker = Agent::TaskWorker.new(@tuple_space, features, @env)
    end

    after do
      @tuple_space.terminate
    end

    it 'should take a task' do
      # make a task with no features
      task = TestUtil::Tuple.task(@env.current_package_id, 'R1', [], nil, FeatureSequence.new)

      # publish the task
      write(task)

      # take it
      @worker.transit_to_init
      @worker.transit_to_take_task.should == task
    end

    it 'should timeout because of unmatched features' do
      # make a task with feature "+X"
      task = TestUtil::Tuple.task(@env.current_package_id, 'R2', [], nil, TestUtil::Lang.expr!(@env, '+X'))

      # publish the task
      write(task)

      # try to take it
      should.raise(Timeout::Error) do
        timeout(1) do
          @worker.transit_to_init
          @worker.transit_to_take_task
        end
      end
    end

    it 'should take a task because of features' do
      # make a task with feature "+A"
      task = TestUtil::Tuple.task(@env.current_package_id, 'R2', [], nil, TestUtil::Lang.expr!(@env, '+A'))

      # publish the task
      write(task)

      # take it
      @worker.transit_to_take_task.should == task
    end

    it 'should raise an exception because of unknown rule' do
      task = TestUtil::Tuple.task(@env.current_package_id, 'Unknown', [])

      # publish the task
      write(task)

      should.raise(Lang::UnboundError) do
        @worker.transit_to_execute_task(task)
      end
    end
  end

  describe 'task execution' do
    before do
      @tuple_space = create_tuple_space_server

      # make a data
      data = Tuple[:data].new(name: "a", location: Location[Temppath.create].create("abc"))

      # make a rule
      @env = Lang::Environment.new.setup_new_package("TaskWorker")
      TestUtil::Lang.package_context!(@env, <<-PIONE)
        Rule R
          input  'a'
          output 'b'.stdout
        Action
          echo -n "input: `cat a`"
        End
      PIONE

      # make a task
      @task = TestUtil::Tuple.task(@env.current_package_id, "R", [[data]])

      # write the data
      domain_id = Util::DomainID.generate(@env.current_package_id, "R", [["a"]], ParameterSet.new)
      write(data.set(domain: domain_id))

      # setup workers
      @worker1 = Agent::TaskWorker.start(@tuple_space, FeatureSequence.new, @env)
      @worker2 = Agent::TaskWorker.start(@tuple_space, FeatureSequence.new, @env)
      @worker3 = Agent::TaskWorker.start(@tuple_space, FeatureSequence.new, @env)

      # workers are waiting tasks
      @worker1.wait_until(:take_task)
      @worker2.wait_until(:take_task)
      @worker3.wait_until(:take_task)
    end

    after do
      @worker1.terminate unless @worker1.terminated?
      @worker2.terminate unless @worker2.terminated?
      @worker3.terminate unless @worker3.terminated?
      @tuple_space.terminate
    end

    it "should wait tasks" do
      # check agent state
      @worker1.states.should == [Agent::AgentState.new(:init, :take_task)]
      @worker2.states.should == [Agent::AgentState.new(:init, :take_task)]
      @worker3.states.should == [Agent::AgentState.new(:init, :take_task)]
    end

    it "should process tasks" do
      # terminate worker2,3
      @worker2.terminate
      @worker3.terminate
      @worker2.wait_until_terminated
      @worker3.wait_until_terminated

      # check state
      @worker1.states.should == [Agent::AgentState.new(:init, :take_task)]
      @worker2.chain_threads.list.should.empty
      @worker3.chain_threads.list.should.empty

      # publish the task
      write(@task)
      @worker1.wait_until_before(:take_task)

      # check finished tuple
      finished = read(Tuple[:finished].any)

      # check result data
      data = read(Tuple[:data].new(name: "b", domain: @task.domain_id))
      data.location.read.should == "input: abc"
    end
  end
end
