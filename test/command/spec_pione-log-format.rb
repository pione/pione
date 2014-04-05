require 'pione/test-helper'
require_relative 'command-behavior'

describe Pione::Command::PioneLogFormat do
  raw_log_location = Location[File.dirname(__FILE__)] + "data" + "pione-process.log"

  before do
    @cmd = Pione::Command::PioneLogFormat
  end

  behaves_like "command"

  it "should generate rule process log" do
    cmd = @cmd.new(["--trace-type", "rule", raw_log_location.path.to_s])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.chomp.size.should > 0
  end

  it "should generate task process log" do
    cmd = @cmd.new(["--trace-type", "trace", raw_log_location.path.to_s])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.chomp.size.should > 0
  end

  it "should fail if format is unknown" do
    cmd = @cmd.new(["--format", "xxx", raw_log_location.path.to_s])
    Rootage::ScenarioTest.fail(cmd)
  end
end
