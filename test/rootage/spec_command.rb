require 'rootage/test-helper'

describe Rootage::CommandPhase do
  it "should be a phase" do
    phase = Rootage::CommandPhase.new
    phase.use(:test) {|item| item.assign {1}}
    phase.table.size.should == 1
    phase.list.size.should == 1
    phase.should.kind_of Rootage::Phase
  end
end

describe Rootage::Command do
  it "should run" do
    klass = Rootage::Command.make do
      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {1}}
        phase.use(:test2) {|item| item.assign {2}}
        phase.use(:test3) {|item| item.assign {3}}
      end
    end

    scenario = klass.new([])
    Rootage::ScenarioTest.succeed(scenario)

    scenario.model[:test1].should == 1
    scenario.model[:test2].should == 2
    scenario.model[:test3].should == 3
  end

  it "should run with a argument" do
    klass = Rootage::Command.make do
      argument(:arg1) do |item|
        item.type = :integer
      end

      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {1 * model[:arg1]}}
        phase.use(:test2) {|item| item.assign {2 * model[:arg1]}}
        phase.use(:test3) {|item| item.assign {3 * model[:arg1]}}
      end
    end

    scenario1 = klass.new(["1"])
    Rootage::ScenarioTest.succeed(scenario1)

    scenario2 = klass.new(["2"])
    Rootage::ScenarioTest.succeed(scenario2)

    scenario3 = klass.new(["3"])
    Rootage::ScenarioTest.succeed(scenario3)

    scenario1.model.tap do |model|
      model[:arg1].should == 1
      model[:test1].should == 1
      model[:test2].should == 2
      model[:test3].should == 3
    end

    scenario2.model.tap do |model|
      model[:arg1].should == 2
      model[:test1].should == 2
      model[:test2].should == 4
      model[:test3].should == 6
    end

    scenario3.model.tap do |model|
      model[:arg1].should == 3
      model[:test1].should == 3
      model[:test2].should == 6
      model[:test3].should == 9
    end
  end

  it "should run with arguments" do
    klass = Rootage::Command.make do
      argument(:arg1) do |item|
        item.type = :string
      end

      argument(:arg2) do |item|
        item.type = :integer
      end

      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {model[:arg1] * model[:arg2]}}
      end
    end

    scenario1 = klass.new(["a", "1"])
    Rootage::ScenarioTest.succeed(scenario1)

    scenario2 = klass.new(["b", "2"])
    Rootage::ScenarioTest.succeed(scenario2)

    scenario3 = klass.new(["c", "3"])
    Rootage::ScenarioTest.succeed(scenario3)

    scenario1.model.tap do |model|
      model[:arg1].should == "a"
      model[:arg2].should == 1
      model[:test1].should == "a"
    end

    scenario2.model.tap do |model|
      model[:arg1].should == "b"
      model[:arg2].should == 2
      model[:test1].should == "bb"
    end

    scenario3.model.tap do |model|
      model[:arg1].should == "c"
      model[:arg2].should == 3
      model[:test1].should == "ccc"
    end
  end

  it "should run with a option" do
    klass = Rootage::Command.make do
      option(:option1) do |item|
        item.type = :integer
        item.long = "--option1"
        item.arg  = "N"
      end

      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {1 * model[:option1]}}
        phase.use(:test2) {|item| item.assign {2 * model[:option1]}}
        phase.use(:test3) {|item| item.assign {3 * model[:option1]}}
      end
    end

    scenario1 = klass.new(["--option1","1"])
    Rootage::ScenarioTest.succeed(scenario1)

    scenario2 = klass.new(["--option1", "2"])
    Rootage::ScenarioTest.succeed(scenario2)

    scenario3 = klass.new(["--option1", "3"])
    Rootage::ScenarioTest.succeed(scenario3)

    scenario1.model.tap do |model|
      model[:option1].should == 1
      model[:test1].should == 1
      model[:test2].should == 2
      model[:test3].should == 3
    end

    scenario2.model.tap do |model|
      model[:option1].should == 2
      model[:test1].should == 2
      model[:test2].should == 4
      model[:test3].should == 6
    end

    scenario3.model.tap do |model|
      model[:option1].should == 3
      model[:test1].should == 3
      model[:test2].should == 6
      model[:test3].should == 9
    end
  end

  it "should run with options" do
    klass = Rootage::Command.make do
      option(:option1) do |item|
        item.type = :string
        item.long = "--option1"
        item.arg  = "N"
      end

      option(:option2) do |item|
        item.type = :integer
        item.long = "--option2"
        item.arg  = "STR"
      end

      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {model[:option1] * model[:option2]}}
      end
    end

    scenario1 = klass.new(["--option1", "a", "--option2", "1"])
    Rootage::ScenarioTest.succeed(scenario1)

    scenario2 = klass.new(["--option1", "b", "--option2", "2"])
    Rootage::ScenarioTest.succeed(scenario2)

    scenario3 = klass.new(["--option1", "c", "--option2", "3"])
    Rootage::ScenarioTest.succeed(scenario3)

    scenario1.model.tap do |model|
      model[:option1].should == "a"
      model[:option2].should == 1
      model[:test1].should == "a"
    end

    scenario2.model.tap do |model|
      model[:option1].should == "b"
      model[:option2].should == 2
      model[:test1].should == "bb"
    end

    scenario3.model.tap do |model|
      model[:option1].should == "c"
      model[:option2].should == 3
      model[:test1].should == "ccc"
    end
  end
end

describe Rootage::StandardCommand do
  it "should run" do
    klass = Rootage::StandardCommand.make do
      phase(:setup) do |phase|
        phase.use(:test1) {|item| item.assign {1}}
        phase.use(:test2) {|item| item.assign {2}}
        phase.use(:test3) {|item| item.assign {3}}
      end
      phase(:execution) do |phase|
        phase.use(:test1) {|item| item.assign {model[:test1] + 1}}
        phase.use(:test2) {|item| item.assign {model[:test2] + 2}}
        phase.use(:test3) {|item| item.assign {model[:test3] + 3}}
      end
      phase(:termination) do |phase|
        phase.use(:test1) {|item| item.assign {model[:test1] + 1}}
        phase.use(:test2) {|item| item.assign {model[:test2] + 2}}
        phase.use(:test3) {|item| item.assign {model[:test3] + 3}}
      end
    end

    scenario = klass.new([])
    Rootage::ScenarioTest.succeed(scenario)

    scenario.model[:test1].should == 3
    scenario.model[:test2].should == 6
    scenario.model[:test3].should == 9
  end
end
