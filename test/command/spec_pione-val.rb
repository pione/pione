require 'pione/test-helper'
require 'pione/command/pione-val'
require_relative 'command-behavior'

describe Pione::Command::PioneVal do
  before do
    @cmd = Pione::Command::PioneVal
  end

  behaves_like "command"

  it "should get value" do
    cmd = @cmd.new(["1 + 1"])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.chomp.should == "2"
  end

  it "should get variable from domain info" do
    domain_info = Location[File.dirname(__FILE__)] + "data" + "pione-val.domain.dump"
    cmd = @cmd.new(["$O[1]", "--domain-dump", domain_info.path.to_s])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.chomp.should == "message.txt"
  end
end

