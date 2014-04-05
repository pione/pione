require 'pione/test-helper'

describe Pione::Command::PioneDiagnosisNotification do
  before do
    @cmd = Pione::Command::PioneDiagnosisNotification
  end

  it "should diagnose fine notification connection" do
    options = [
      "--notification-target", "pnb://127.0.0.1",
      "--timeout", "5"
    ]
    Rootage::ScenarioTest.succeed(@cmd.new(options))
  end

  it "should diagnose bad notification connetction" do
    options = [
      "--notification-target", "pnb://192.0.2.1",
      "--timeout", "3"
    ]
    Rootage::ScenarioTest.fail(@cmd.new(options))
  end
end
