require "pione/test-helper"

describe Pione::Command::PioneConfig do
  before do
    @cmd = Pione::Command::PioneConfig

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

    args1 = ["--get", "test1", "-f", @path.to_s]
    res1 = TestHelper::Command.succeed(@cmd, args1)
    res1.stdout.string.chomp.should == "a"

    args2 = ["--get", "test2", "-f", @path.to_s]
    res2 = TestHelper::Command.succeed(@cmd, args2)
    res2.stdout.string.chomp.should == "1"

    args3 = ["--get", "test3", "-f", @path.to_s]
    res3 = TestHelper::Command.succeed(@cmd, args3)
    res3.stdout.string.chomp.should == "true"
  end

  it "should list all" do
    config = Global::Config.new(@path)
    config.set(:test1, "a")
    config.set(:test2, 1)
    config.set(:test3, true)
    config.save

    res = TestHelper::Command.succeed(@cmd, ["--list", "-f", @path.to_s])

    list = res.stdout.string.split("\n")
    list.should.include("test1: a")
    list.should.include("test2: 1")
    list.should.include("test3: true")
  end

  it "should set items" do
    TestHelper::Command.succeed(@cmd, ["--set", "test1", "a", "-f", @path.to_s])
    TestHelper::Command.succeed(@cmd, ["--set", "test2", "1", "-f", @path.to_s])
    TestHelper::Command.succeed(@cmd, ["--set", "test3", "true", "-f", @path.to_s])

    config = Global::Config.new(@path)
    config[:test1].should == "a"
    config[:test2].should == 1
    config[:test3].should.true
  end

  it "should unset items" do
    config = Global::Config.new(@path)
    config.set(:test1, "a")
    config.set(:test2, 1)
    config.set(:test3, true)
    config.save

    TestHelper::Command.succeed(@cmd, ["--unset", "test1", "-f", @path.to_s])
    TestHelper::Command.succeed(@cmd, ["--unset", "test2", "-f", @path.to_s])
    TestHelper::Command.succeed(@cmd, ["--unset", "test3", "-f", @path.to_s])

    config = Global::Config.new(@path)
    config[:test1].should.nil
    config[:test2].should.nil
    config[:test3].should.nil
  end
end
