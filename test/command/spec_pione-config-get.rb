require "pione/test-helper"

describe Pione::Command::PioneConfigGet do
  before do
    @cmd = Pione::Command::PioneConfigGet

    Global.define_external_item(:test1) do |item|
      item.type = :string
    end

    Global.define_external_item(:test2) do |item|
      item.type = :integer
    end

    Global.define_external_item(:test3) do |item|
      item.type = :boolean
    end

    @path = Temppath.create
  end

  after do
    Global.item[:test1].unregister
    Global.item[:test2].unregister
    Global.item[:test3].unregister
  end

  it "should get item value" do
    config = Global::Config.new(@path)
    config.set(:test1, "a")
    config.set(:test2, 1)
    config.set(:test3, true)
    config.save

    cmd1  = @cmd.new(["-f", @path.to_s, "test1"])
    res1 = Rootage::ScenarioTest.succeed(cmd1)
    res1.stdout.string.chomp.should == "a"

    cmd2 = @cmd.new(["-f", @path.to_s, "test2"])
    res2 = Rootage::ScenarioTest.succeed(cmd2)
    res2.stdout.string.chomp.should == "1"

    cmd3 = @cmd.new(["-f", @path.to_s, "test3"])
    res3 = Rootage::ScenarioTest.succeed(cmd3)
    res3.stdout.string.chomp.should == "true"
  end
end
