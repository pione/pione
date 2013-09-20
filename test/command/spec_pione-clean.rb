require_relative '../test-util'
require_relative 'command-behavior'

describe "Pione::Command::PioneClean" do
  behaves_like "command"

  it "should clean temporary files" do
    res = TestUtil::Command.succeed do
      Command::PioneClean.run []
    end
  end
end
