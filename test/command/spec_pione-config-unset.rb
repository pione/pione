require "pione/test-helper"

describe Pione::Command::PioneConfigUnset do
  before do
    @cmd = Pione::Command::PioneConfigUnset

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

  it "should unset items" do
    config = Global::Config.new(@path)
    config.set(:test1, "a")
    config.set(:test2, 1)
    config.set(:test3, true)
    config.save

    Rootage::ScenarioTest.succeed(@cmd.new(["-f", @path.to_s, "test1"]))
    Rootage::ScenarioTest.succeed(@cmd.new(["-f", @path.to_s, "test2"]))
    Rootage::ScenarioTest.succeed(@cmd.new(["-f", @path.to_s, "test3"]))

    config = Global::Config.new(@path)
    config[:test1].should.nil
    config[:test2].should.nil
    config[:test3].should.nil
  end
end
