require 'rootage/test-helper'

Rootage.scope do |this|
  class this::E1 < StandardError; end

  describe Rootage::Action do
    it "should execute an action" do
      val1 = nil
      val2 = nil
      val3 = nil

      scenario = Rootage::Scenario.new
      scenario << Rootage::Action.new.tap do |item|
        item.name = :test
        item.process { val1 = 1 }
        item.process { val2 = 2 }
        item.process { val3 = 3 }
      end

      # check pre-state
      val1.should.nil
      val2.should.nil
      val3.should.nil

      # run
      Rootage::ScenarioTest.succeed(scenario)

      # check post-state
      val1.should == 1
      val2.should == 2
      val3.should == 3
    end

    it "should assign process result into model" do
      scenario = Rootage::Scenario.new
      scenario << Rootage::Action.new.tap do |item|
        item.name = :test
        item.assign { 0 }
        item.assign(:var1) { 1 }
        item.assign(:var2) { 2 }
        item.assign(:var3) { 3 }
      end
      model = scenario.model

      # check pre-state
      model[:test].should.nil
      model[:var1].should.nil
      model[:var2].should.nil
      model[:var3].should.nil

      # run
      Rootage::ScenarioTest.succeed(scenario)

      # check post-state
      model[:test].should == 0
      model[:var1].should == 1
      model[:var2].should == 2
      model[:var3].should == 3
    end

    it "should execute processes in order" do
      scenario = Rootage::Scenario.new
      scenario << Rootage::Action.new.tap do |item|
        item.name = :test
        item.assign { 0 }
        item.assign(:var1) { model[:test] + 1 }
        item.assign(:var2) { model[:var1] + 1 }
        item.assign(:var3) { model[:var2] + 1 }
      end
      model = scenario.model

      # check pre-state
      model[:test].should.nil
      model[:var1].should.nil
      model[:var2].should.nil
      model[:var3].should.nil

      # run
      Rootage::ScenarioTest.succeed(scenario)

      # check post-state
      model[:test].should == 0
      model[:var1].should == 1
      model[:var2].should == 2
      model[:var3].should == 3
    end

    it "should handle test failures" do
      val1 = nil
      val2 = nil

      scenario = Rootage::Scenario.new
      scenario << Rootage::Action.new.tap do |item|
        item.name = :test
        item.process { test(true) ; val1 = 1 }
        item.process { test(false); val2 = 2 }
        item.assign(:var1) { test(true) ; 3 }
        item.assign(:var2) { test(false); 4 }
      end
      model = scenario.model

      # check pre-state
      val1.should.nil
      val2.should.nil
      model[:var1].should.nil
      model[:var2].should.nil

      # run
      Rootage::ScenarioTest.succeed(scenario)

      # check post-state
      val1.should == 1
      val2.should.nil
      model[:var1].should == 3
      model[:var2].should.nil
    end

    it "should quit halfway because of test failure" do
      scenario = Rootage::Scenario.new
      scenario << Rootage::Action.new.tap do |item|
        item.name = :test
        item.assign(:var1) {1}
        item.condition { test(true) }
        item.assign(:var2) {2}
        item.condition { test(false) }
        item.assign(:var3) {3}
      end
      model = scenario.model

      # check pre-state
      model[:var1].should.nil
      model[:var2].should.nil
      model[:var3].should.nil

      # run
      Rootage::ScenarioTest.succeed(scenario)

      # check post-state
      model[:var1].should == 1
      model[:var2].should == 2
      model[:var3].should.nil
    end

    it "should use specified context" do
      class this::TestContext < Rootage::ProcessContext
        def test1; 1       ; end
        def test2; scenario; end
        def test3; model   ; end
      end

      scenario = Rootage::Scenario.new
      scenario << Rootage::Action.new.tap do |item|
        item.name = :test
        item.process_context_class = this::TestContext

        item.assign(:var1) { test1 }
        item.assign(:var2) { test2 }
        item.assign(:var3) { test3 }
      end
      model = scenario.model

      # check pre-state
      model[:var1].should.nil
      model[:var2].should.nil
      model[:var3].should.nil

      # run
      Rootage::ScenarioTest.succeed(scenario)

      # check post-state

      model[:var1].should == 1
      model[:var2].should == scenario
      model[:var3].should == model
    end

    it "should handle an exception" do
      val = nil

      scenario = Rootage::Scenario.new([])
      scenario << Rootage::Action.new.tap do |item|
        item.name = :test

        item.process { raise this::E1 }
        item.exception(this::E1) { val = true }
      end

      # check pre-state
      val.should.nil

      # run
      Rootage::ScenarioTest.succeed(scenario)

      # check post-state
      val.should.true
    end
  end
end
