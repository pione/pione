require 'pione/test-helper'

describe Pione::Command::PioneAction do
  before do
    @cmd = Pione::Command::PioneAction
  end

  it "should fail with no subcommands" do
    TestHelper::Command.fail(@cmd, [])
  end
end
