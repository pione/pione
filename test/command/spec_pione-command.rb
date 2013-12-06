require 'pione/test-helper'
require_relative 'command-behavior'

describe Pione::Command::PioneCommand do
  before do
    @cmd = Pione::Command::PioneCommand
  end

  behaves_like "command"

  it "should call subcommand" do
    TestHelper::Command.succeed(@cmd, ["val", "1 + 1"])
  end

  it "should fail with unknown subcommand name" do
    TestHelper::Command.fail(@cmd, ["abcdefghijk"])
  end
end
