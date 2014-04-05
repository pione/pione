require 'pione/test-helper'
require_relative 'command-behavior'

describe Pione::Command::PioneLog do
  before do
    @cmd = Pione::Command::PioneLog
  end

  behaves_like "command"

  it "should fail with no subcommands" do
    Rootage::ScenarioTest.fail(@cmd.new([]))
  end
end
