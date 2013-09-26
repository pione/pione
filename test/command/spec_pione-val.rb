require 'pione/test-helper'
require_relative 'command-behavior'

describe "Pione::Command::PioneVal" do
  behaves_like "command"

  it "should get value" do
    res = TestHelper::Command.succeed do
      Command::PioneVal.run ["1 + 1"]
    end
    res.stdout.string.chomp.should == "2"
  end

  it "should get variable from domain info" do
    domain_info = Location[File.dirname(__FILE__)] + "data" + "pione-val.domain.dump"
    res = TestHelper::Command.succeed do
      Command::PioneVal.run ["$O[1]", "--domain-info", domain_info.path.to_s]
    end
    res.stdout.string.chomp.should == "message.txt"
  end
end

