require 'pione/test-helper'

TestHelper.scope do |this|
  this::PACKAGE_DIR = Location[File.dirname(__FILE__)] + "data"

  describe Pione::Package::ScenarioHandler do
    before do
      @location = this::PACKAGE_DIR + "TestPackage1"
      @case1 = Package::ScenarioReader.new(@location + "scenario/case1").read
      @case2 = Package::ScenarioReader.new(@location + "scenario/case2").read
      @case3 = Package::ScenarioReader.new(@location + "scenario/case3").read
    end

    it "should get the scenario name" do
      @case1.info.name.should == "Case1"
      @case2.info.name.should == "Case2"
      @case3.info.name.should == "Case3"
    end

    it "should get input files" do
      @case1.inputs[0].basename.should == "1.txt"
      case2_inputs = @case2.inputs.map{|input| input.basename}
      case2_inputs.size.should == 3
      case2_inputs.should.include "1.txt"
      case2_inputs.should.include "2.txt"
      case2_inputs.should.include "3.txt"
      case3_inputs = @case3.inputs.map{|input| input.basename}
      case3_inputs.size.should == 2
      case3_inputs.should.include "a.txt"
      case3_inputs.should.include "b.txt"
    end

    it "should get output files" do
      @case1.outputs[0].basename.should == "1.count"
      case2_outputs = @case2.outputs.map{|output| output.basename}
      case2_outputs.size.should == 3
      case2_outputs.should.include "1.count"
      case2_outputs.should.include "2.count"
      case2_outputs.should.include "3.count"
      case3_outputs = @case3.outputs.map{|output| output.basename}
      case3_outputs.size.should == 2
      case3_outputs.should.include "a.count"
      case3_outputs.should.include "b.count"
    end
  end
end
