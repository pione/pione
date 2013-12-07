require 'pione/test-helper'
require_relative 'command-behavior'

describe Pione::Command::PioneLog do
  raw_log_location = Location[File.dirname(__FILE__)] + "data" + "pione-process.log"

  before do
    @cmd = Pione::Command::PioneLog
  end

  behaves_like "command"

  it "should generate rule process log" do
    args = ["--rule-process", "--location", raw_log_location.path.to_s]
    res = TestHelper::Command.succeed(@cmd, args)
    res.stdout.string.chomp.size.should > 0
  end

  it "should generate task process log" do
    args = ["--task-process", "--location", raw_log_location.path.to_s]
    res = TestHelper::Command.succeed(@cmd, args)
    res.stdout.string.chomp.size.should > 0
  end

  it "should fail if format is unknown" do
    args = ["--format", "xxx", "--location", raw_log_location.path.to_s]
    TestHelper::Command.fail(@cmd, args)
  end
end
