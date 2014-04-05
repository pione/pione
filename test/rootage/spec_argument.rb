require 'rootage/test-helper'

describe Rootage::Argument do
  it "should parse argument" do
    cmd = Rootage::Command.new(["/path/to/a"])
    cmd.define(:name, "test")

    cmd << Rootage::Argument.new.tap do |item|
      item.name = "arg1"
      item.type = :path
    end

    # run
    Rootage::ScenarioTest.succeed(cmd)

    cmd.model[:arg1].should == Pathname.new("/path/to/a")
  end
end
