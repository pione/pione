require "pione/test-helper"

describe Pione::Command::PioneConfigList do
  before do
    @cmd = Pione::Command::PioneConfigList

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

  it "should list all" do
    config = Global::Config.new(@path)
    config.set(:test1, "a")
    config.set(:test2, 1)
    config.set(:test3, true)
    config.save

    res = Rootage::ScenarioTest.succeed(@cmd.new(["-f", @path.to_s]))

    list = res.stdout.string.split("\n")
    list.should.include("test1: a")
    list.should.include("test2: 1")
    list.should.include("test3: true")
  end
end
