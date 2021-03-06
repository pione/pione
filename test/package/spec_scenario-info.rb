require 'pione/test-helper'

describe Pione::Package::ScenarioInfo do
  it "should generate a JSON and read it" do
    info = Package::ScenarioInfo.read(JSON.generate(Package::ScenarioInfo.new(
          name: "S1",
          textual_param_sets: "{}",
          inputs: ["input/i1", "input/i2", "input/i3"],
          outputs: ["output/o1", "output/o2", "output/o3"]
    )))
    info.name.should == "S1"
    info.textual_param_sets.should == "{}"
    info.inputs.should == ["input/i1", "input/i2", "input/i3"]
    info.outputs.should == ["output/o1", "output/o2", "output/o3"]
  end
end
