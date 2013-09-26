require 'pione/test-helper'
require_relative 'command-behavior'

describe "Pione::Command::PioneClean" do
  behaves_like "command"

  it "should clean temporary files" do
    res = TestHelper::Command.succeed do
      Command::PioneClean.run []
    end
  end
end
