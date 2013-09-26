require 'pione/test-helper'

describe 'Pione::RuleHandler::FlowRule' do
  describe "simple" do
    location = Location[File.dirname(__FILE__)] + "spec_flow-handler.pione"
    env = Lang::Environment.new.setup_new_package("SpecFlowHandler")
    opt = {package_name: "SpecFlowHandler", filename: "spec_flow-handler.pione"}
    context = Component::Document.load(location, opt)
    context.eval(env)

    before do
      @ts = TestHelper::TupleSpace.create(self)

      # setup data
      location = Location[Temppath.create]
      location_a = location + "1.a"
      location_b = location + "1.b"
      location_a.create("1")
      location_b.create("2")

      # rule
      @package_id = "SpecFlowHandler"
      @rule_name = "Test"
      param_set = Lang::ParameterSet.new(table: {"*" => Lang::StringSequence.of("1")})

      tuple_a = Tuple[:data].new(name: '1.a', location: location_a, time: Time.now)
      tuple_b = Tuple[:data].new(name: '1.b', location: location_b, time: Time.now)
      inputs = [tuple_a, tuple_b]

      domain_id = Util::DomainID.generate(@package_id, @rule_name, inputs, param_set)
      tuple_a.domain = domain_id
      tuple_b.domain = domain_id
      inputs.each {|t| write(t) }

      @handler = RuleEngine.make(@ts, env, @package_id, @rule_name, inputs, param_set, domain_id, 'root')
    end

    after do
      @ts.terminate
    end

    it "should have base-location" do
      @handler.base_location.should == @ts.base_location
    end

    it "should have domain id" do
      @handler.domain_id.split(":").tap do |(package_id, rule_name, task_id)|
        package_id.should == "SpecFlowHandler"
        rule_name.should == "Test"
        task_id.should.not.nil
      end
    end

    it "should execute a flow" do
      # start the handler
      thread = Thread.new { Thread.current[:outputs] = @handler.execute }

      # check tasks in space
      task = read(Tuple[:task].new)
      task.package_id.should == @package_id
      task.rule_name.should == "Shell"
      task.inputs.flatten.map{|d| d.name}.sort.should == ['1.a', '1.b']
      task.param_set.keys.should.include "I"
      task.param_set.keys.should.include "INPUT"

      # make task worker and wait
      task_worker = Agent[:task_worker].start(@ts, Lang::FeatureSequence.new, env)
      thread.join

      outputs = thread[:outputs]
      outputs.size.should == 1
      outputs[0][0].name.should == '1.c'
      should.not.raise do
        read(Tuple[:data].new(name: '1.c', domain: @handler.domain_id))
      end
    end
  end

  describe "redundant task unification" do
    before do
      @space = TestHelper::TupleSpace.create(self)

      # package "Abstract"
      @env = Lang::Environment.new.setup_new_package("Unification")
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R1
          output 'message.txt'
        Flow
          rule R2
          rule R2
        End

        Rule R2
          output 'message.txt'
        Action
          echo "R2" > message.txt
        End
      PIONE
    end

    after do
      @space.terminate
    end

    it "should unify redundant tasks" do
      param_set = Lang::ParameterSet.new
      domain_id = Util::DomainID.generate('Unification', 'R1', [], param_set)
      handler = RuleEngine.make(@space, @env, 'Unification', 'R1', [], param_set, domain_id, 'root')

      # start the handler
      thread = Thread.new { Thread.current[:outputs] = handler.execute }

      # check tasks in space
      sleep 1
      tasks = read_all(Tuple[:task].new)
      tasks.size.should == 1

      # make task worker and wait
      task_worker = Agent[:task_worker].start(@space, Lang::FeatureSequence.new, @env)
      thread.join

      outputs = thread[:outputs]
      outputs.size.should == 1
      outputs[0][0].name.should == 'message.txt'
      should.not.raise do
        read(Tuple[:data].new(name: 'message.txt', domain: handler.domain_id))
      end
    end
  end

  describe "rule branch" do
    before do
      @space = TestHelper::TupleSpace.create(self)

      @env = Lang::Environment.new.setup_new_package("Branch")
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule Main
          output '*.o'
          param $F := true
        Flow
          if $F
            rule A
          else
            rule B
          end
        End

        Rule A
          output 'a.o'
        Action
          echo 'This is rule A' > a.o
        End

        Rule B
          output 'b.o'
        Action
          echo 'This is rule B' > b.o
        End
      PIONE
    end

    after do
      @space.terminate
    end

    it "should exist rules" do
      @env.rule_get(Lang::RuleExpr.new("Main")).should.kind_of Lang::RuleDefinition
      @env.rule_get(Lang::RuleExpr.new("A")).should.kind_of Lang::RuleDefinition
      @env.rule_get(Lang::RuleExpr.new("B")).should.kind_of Lang::RuleDefinition
    end

    it "should execute a flow" do
      param_set = Lang::ParameterSet.new(table: {"F" => Lang::BooleanSequence.of("true")})
      domain_id = Util::DomainID.generate(@env.current_package_id, 'Main', [], param_set)
      handler = RuleEngine.make(@space, @env, @env.current_package_id, 'Main', [], param_set, domain_id, 'root')

      # start the handler
      thread = Thread.new { Thread.current[:outputs] = handler.execute }

      # check tasks in space
      task = read(Tuple[:task].new)
      task.package_id.should == @env.current_package_id
      task.rule_name.should == "A"
      task.inputs.should == []

      # make task worker and wait
      task_worker = Agent[:task_worker].start(@space, Lang::FeatureSequence.new, @env)
      thread.join

      outputs = thread[:outputs]
      outputs.size.should == 1
      outputs[0][0].name.should == 'a.o'
      should.not.raise do
        read(Tuple[:data].new(name: 'a.o', domain: handler.domain_id))
      end
    end
  end

  describe "rule override" do
    before do
      @space = TestHelper::TupleSpace.create(self)

      # package "Parent"
      _env = Lang::Environment.new.setup_new_package("Parent")
      TestHelper::Lang.package_context!(_env, <<-PIONE)
        Rule R1
          output '*-message.txt'
        Flow
          rule R2
        End

        Rule R2
          output 'parent-message.txt'
        Action
          echo "parent" > parent-message.txt
        End
      PIONE

      # package "Child"
      @env = _env.setup_new_package("Child", "Parent")
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R2
          output 'child-message.txt'
        Action
          echo "child" > child-message.txt
        End
      PIONE
    end

    after do
      @space.terminate
    end

    it "should override parent rule by child" do
      param_set = Lang::ParameterSet.new
      domain_id = Util::DomainID.generate('Child', 'R1', [], param_set)
      handler = RuleEngine.make(@space, @env, 'Child', 'R1', [], param_set, domain_id, 'root')

      # start the handler
      thread = Thread.new { Thread.current[:outputs] = handler.execute }

      # check tasks in space
      task = read(Tuple[:task].new)
      task.package_id.should == "Child"
      task.rule_name.should == "R2"
      task.inputs.should == []

      # make task worker and wait
      task_worker = Agent[:task_worker].start(@space, Lang::FeatureSequence.new, @env)
      thread.join

      outputs = thread[:outputs]
      outputs.size.should == 1
      outputs[0][0].name.should == 'child-message.txt'
      # outputs[0][0].location.read.should == "child"
      should.not.raise do
        read(Tuple[:data].new(name: 'child-message.txt', domain: handler.domain_id))
      end
    end
  end

  describe "abstract rule" do
    before do
      @space = TestHelper::TupleSpace.create(self)

      # package "Abstract"
      _env = Lang::Environment.new.setup_new_package("Abstract")
      TestHelper::Lang.package_context!(_env, <<-PIONE)
        Rule R1
          output 'message.txt'
        Flow
          rule R2
        End
      PIONE

      # package "Concrete"
      @env = _env.setup_new_package("Concrete", "Abstract")
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R2
          output 'message.txt'
        Action
          echo "R2" > message.txt
        End
      PIONE
    end

    after do
      @space.terminate
    end

    it "should get concrete rule" do
      param_set = Lang::ParameterSet.new
      domain_id = Util::DomainID.generate('Concrete', 'R1', [], param_set)
      handler = RuleEngine.make(@space, @env, 'Concrete', 'R1', [], param_set, domain_id, 'root')

      # start the handler
      thread = Thread.new { Thread.current[:outputs] = handler.execute }

      # check tasks in space
      task = read(Tuple[:task].new)
      task.package_id.should == "Concrete"
      task.rule_name.should == "R2"
      task.inputs.should == []

      # make task worker and wait
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      thread.join

      outputs = thread[:outputs]
      outputs.size.should == 1
      outputs[0][0].name.should == 'message.txt'
      # outputs[0][0].location.read.should == "child"
      should.not.raise do
        read(Tuple[:data].new(name: 'message.txt', domain: handler.domain_id))
      end
    end
  end

  describe "distribution by parameter" do
    before do
      @space = TestHelper::TupleSpace.create(self)

      @env = Lang::Environment.new.setup_new_package("ParamDist")
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R1
          output '*.o'.all
        Flow
          rule R2 {X: 1 | 2 | 3}
        End

        Rule R2
          output '{$X}.o'.touch
          param $X := 1
        End
      PIONE
    end

    after do
      @space.terminate
    end

    it "should distribute tasks by parameter" do
      param_set = Lang::ParameterSet.new
      domain_id = Util::DomainID.generate(@env.current_package_id, 'R1', [], param_set)
      handler = RuleEngine.make(@space, @env, @env.current_package_id, 'R1', [], param_set, domain_id, 'root')

      # start the handler
      thread = Thread.new { Thread.current[:outputs] = handler.execute }

      # check tasks in space
      read(Tuple[:task].new)
      sleep 1
      tasks = read_all(Tuple[:task].new)

      # make task worker and wait
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      thread.join

      outputs = thread[:outputs]
      outputs.size.should == 1
      outputs[0].map{|t| t.name}.sort.should == ['1.o', '2.o', '3.o']
      should.not.raise do
        read(Tuple[:data].new(name: '1.o', domain: handler.domain_id))
        read(Tuple[:data].new(name: '2.o', domain: handler.domain_id))
        read(Tuple[:data].new(name: '3.o', domain: handler.domain_id))
      end
    end
  end

  describe "recursion by parameter" do
    before do
      @space = TestHelper::TupleSpace.create(self)

      @env = Lang::Environment.new.setup_new_package("Recursion")
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R1
          output '*.o'.all
          param $X := 5
        Flow
          if $X > 1
            rule R1 {X: $X - 1}
          end
          rule R2 {X: $X}
        End

        Rule R2
          output '{$X}.o'.touch
          param $X := 1
        End
      PIONE
    end

    after do
      @space.terminate
    end

    it "should make recursion by using parameter" do
      param_set = Lang::ParameterSet.new
      domain_id = Util::DomainID.generate(@env.current_package_id, 'R1', [], param_set)
      handler = RuleEngine.make(@space, @env, @env.current_package_id, 'R1', [], param_set, domain_id, 'root')

      # start the handler
      thread = Thread.new { Thread.current[:outputs] = handler.execute }

      # check tasks in space
      read(Tuple[:task].new)

      # make task worker and wait
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      task_worker = Agent::TaskWorker.start(@space, Lang::FeatureSequence.new, @env)
      thread.join

      outputs = thread[:outputs]
      outputs.size.should == 1
      outputs[0].map{|t| t.name}.sort.should == ['1.o', '2.o', '3.o', '4.o', '5.o']
    end
  end

end
