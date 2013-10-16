require 'pione/test-helper'

TestHelper.scope do |this|
  # simple scenario
  this::S1 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS1"

  # scenario without inputs
  this::S2 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS2"

  # scenario with parameter set
  this::S3 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS3"

  # invalid scenario because of no scenario names
  this::S4 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS4"

  # invalid scenario because of multiple scenario names
  this::S5 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS5"

  # invalid scenario because of multiple parameter sets
  this::S6 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS6"

  # broken scenario that doesn't have scenario document
  this::S7 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS7"

  # broken scenario that raises parser error
  this::S8 = Location[File.dirname(__FILE__)] + "data" + "ScenarioScannerS8"

  describe Pione::Package::ScenarioScanner do
    it "should scan scenario direcotry: S1" do
      s1 = Package::ScenarioScanner.new(this::S1).scan
      s1.name.should == "S1"
      s1.param_set.should.nil
      s1.inputs.size.should == 3
      s1.inputs.should.include Pathname.new("input/i1")
      s1.inputs.should.include Pathname.new("input/i2")
      s1.inputs.should.include Pathname.new("input/i3")
      s1.outputs.size.should == 3
      s1.outputs.should.include Pathname.new("output/o1")
      s1.outputs.should.include Pathname.new("output/o2")
      s1.outputs.should.include Pathname.new("output/o3")
    end

    it "should scan scenario direcotry: S2" do
      s2 = Package::ScenarioScanner.new(this::S2).scan
      s2.name.should == "S2"
      s2.param_set.should.nil
      s2.inputs.size.should == 0
      s2.outputs.size.should == 1
      s2.outputs.should.include Pathname.new("output/o1")
    end

    it "should scan scenario direcotry: S3" do
      s3 = Package::ScenarioScanner.new(this::S3).scan
      s3.name.should == "S3"
      s3.param_set.should == "{PARAM: 1}"
    end

    it "should raise exception because of no scenario names" do
      should.raise(Package::InvalidScenario) do
        Package::ScenarioScanner.new(this::S4).scan
      end
    end

    it "should raise exception because of multiple scenario names" do
      should.raise(Package::InvalidScenario) do
        Package::ScenarioScanner.new(this::S5).scan
      end
    end

    it "should raise exception because of multiple parameter set" do
      should.raise(Package::InvalidScenario) do
        p Package::ScenarioScanner.new(this::S6).scan
      end
    end

    it "should be faluse because of no scenario documents" do
      Package::ScenarioScanner.new(this::S7).scan.should.false
    end

    it "should raise exception because of parser error" do
      should.raise(Package::InvalidScenario) do
        Package::ScenarioScanner.new(this::S8).scan
      end
    end

    it "should raise exception when scanned location is not local" do
      should.raise(Location::NotLocal) do
        Package::ScenarioScanner.new(Location["http://example.com/P/scenario"])
      end
    end
  end
end
