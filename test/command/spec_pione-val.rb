require 'pione/test-helper'
require_relative 'command-behavior'

describe Pione::Command::PioneVal do
  before do
    @cmd = Pione::Command::PioneVal
  end

  behaves_like "command"

  it "should get value" do
    res = TestHelper::Command.succeed(@cmd, ["1 + 1"])
    res.stdout.string.chomp.should == "2"
  end

  it "should get variable from domain info" do
    domain_info = Location[File.dirname(__FILE__)] + "data" + "pione-val.domain.dump"
    args = ["$O[1]", "--domain-info", domain_info.path.to_s]
    res = TestHelper::Command.succeed(@cmd, args)
    res.stdout.string.chomp.should == "message.txt"
  end
end

