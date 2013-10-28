require 'pione/test-helper'
require_relative 'command-behavior'

describe Pione::Command::PioneCommand do
  behaves_like "command"

  it "should call subcommand" do
    TestHelper::Command.succeed do
      Command::PioneCommand.run(["val", "1 + 1"])
    end
  end

  it "should fail with unknown subcommand name" do
    TestHelper::Command.fail do
      Command::PioneCommand.run(["abcdefghijk"])
    end
  end
end
