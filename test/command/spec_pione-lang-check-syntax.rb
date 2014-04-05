require 'pione/test-helper'

describe Pione::Command::PioneLangCheckSyntax do
  before do
    @cmd = Pione::Command::PioneLangCheckSyntax
  end

  it "should check syntax" do
    Rootage::ScenarioTest.succeed(@cmd.new(["-e", "1 + 1"]))
    Rootage::ScenarioTest.fail(@cmd.new(["-e", "1 +"]))
  end
end
