require "pione/test-helper"

describe Pione::Command::PioneConfigSet do
  before do
    @cmd = Pione::Command::PioneConfigSet

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

  it "should set items" do
    Rootage::ScenarioTest.succeed(@cmd.new(["-f", @path.to_s, "test1", "a"]))
    Rootage::ScenarioTest.succeed(@cmd.new(["-f", @path.to_s, "test2", "1"]))
    Rootage::ScenarioTest.succeed(@cmd.new(["-f", @path.to_s, "test3", "true"]))

    config = Global::Config.new(@path)
    config[:test1].should == "a"
    config[:test2].should == 1
    config[:test3].should.true
  end
end
