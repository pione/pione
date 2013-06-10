require_relative '../test-util'
require_relative 'command-behavior'

describe "Pione::Command::PioneVal" do
  behaves_like "command"

  it "should get value" do
    res = TestUtil::Command.succeed do
      Command::PioneVal.run ["1 + 1"]
    end
    res.stdout.string.chomp.should == "2"
  end

  it "should get variable from domain info" do
    domain_info = TestUtil::DIR + "command" + "spec_pione-val.domain.dump"
    res = TestUtil::Command.succeed do
      Command::PioneVal.run ["$O[1]", "--domain-info", domain_info.path.to_s]
    end
    res.stdout.string.chomp.should == "message.txt"
  end
end

