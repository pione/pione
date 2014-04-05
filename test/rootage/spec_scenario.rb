require 'rootage/test-helper'

describe Rootage::Scenario do
  it "should run with single phase" do
    klass = Rootage::Scenario.make do
      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {1}}
        phase.use(:test2) {|item| item.assign {2}}
        phase.use(:test3) {|item| item.assign {3}}
      end
    end

    scenario = klass.new
    Rootage::ScenarioTest.succeed(scenario)

    scenario.model[:test1].should == 1
    scenario.model[:test2].should == 2
    scenario.model[:test3].should == 3
  end

  it "should run with multiple phases" do
    klass = Rootage::Scenario.make do
      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {1}}
      end
      define_phase(:p2) do |phase|
        phase.use(:test2) {|item| item.assign {2}}
      end
      define_phase(:p3) do |phase|
        phase.use(:test3) {|item| item.assign {3}}
      end
    end

    scenario = klass.new
    Rootage::ScenarioTest.succeed(scenario)

    scenario.model[:test1].should == 1
    scenario.model[:test2].should == 2
    scenario.model[:test3].should == 3
  end

  it "should run multiple scenarios" do
    klass1 = Rootage::Scenario.make do
      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {1}}
        phase.use(:test2) {|item| item.assign {2}}
        phase.use(:test3) {|item| item.assign {3}}
      end
    end
    klass2 = Rootage::Scenario.make do
      define_phase(:p2) do |phase|
        phase.use(:test4) {|item| item.assign {4}}
        phase.use(:test5) {|item| item.assign {5}}
        phase.use(:test6) {|item| item.assign {6}}
      end
    end
    klass3 = Rootage::Scenario.make do
      define_phase(:p3) do |phase|
        phase.use(:test7) {|item| item.assign {7}}
        phase.use(:test8) {|item| item.assign {8}}
        phase.use(:test9) {|item| item.assign {9}}
      end
    end

    scenario1 = klass1.new
    Rootage::ScenarioTest.succeed(scenario1)

    scenario2 = klass2.new
    Rootage::ScenarioTest.succeed(scenario2)

    scenario3 = klass3.new
    Rootage::ScenarioTest.succeed(scenario3)

    scenario1.model.tap do |model|
      model[:test1].should == 1
      model[:test2].should == 2
      model[:test3].should == 3
    end

    scenario2.model.tap do |model|
      model[:test4].should == 4
      model[:test5].should == 5
      model[:test6].should == 6
    end

    scenario3.model.tap do |model|
      model[:test7].should == 7
      model[:test8].should == 8
      model[:test9].should == 9
    end
  end

  it "should run multiple scenario instances" do
    klass = Rootage::Scenario.make do
      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {1 * scenario.args.first}}
        phase.use(:test2) {|item| item.assign {2 * scenario.args.first}}
        phase.use(:test3) {|item| item.assign {3 * scenario.args.first}}
      end
    end

    scenario1 = klass.new(1)
    Rootage::ScenarioTest.succeed(scenario1)

    scenario2 = klass.new(2)
    Rootage::ScenarioTest.succeed(scenario2)

    scenario3 = klass.new(3)
    Rootage::ScenarioTest.succeed(scenario3)

    scenario1.model.tap do |model|
      model[:test1].should == 1
      model[:test2].should == 2
      model[:test3].should == 3
    end

    scenario2.model.tap do |model|
      model[:test1].should == 2
      model[:test2].should == 4
      model[:test3].should == 6
    end

    scenario3.model.tap do |model|
      model[:test1].should == 3
      model[:test2].should == 6
      model[:test3].should == 9
    end
  end

  it "should run with custom context" do
    this_context_class = Rootage::ProcessContext.make do
      define_method(:context1) do
        return true
      end
    end

    klass = Rootage::Scenario.make do
      define(:process_context_class, this_context_class)
      define_phase(:p1) do |phase|
        phase.use(:test1) {|item| item.assign {context1}}
      end
    end

    scenario = klass.new
    Rootage::ScenarioTest.succeed(scenario)

    scenario.model[:test1].should.true
  end
end
