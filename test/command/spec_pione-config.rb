require "pione/test-helper"

describe Pione::Command::PioneConfig do
  before do
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

    res1 = TestHelper::Command.succeed do
      Command::PioneConfig.run(["--get", "test1", "-f", @path.to_s])
    end
    res1.stdout.string.chomp.should == "a"

    res2 = TestHelper::Command.succeed do
      Command::PioneConfig.run(["--get", "test2", "-f", @path.to_s])
    end
    res2.stdout.string.chomp.should == "1"

    res3 = TestHelper::Command.succeed do
      Command::PioneConfig.run(["--get", "test3", "-f", @path.to_s])
    end
    res3.stdout.string.chomp.should == "true"
  end

  it "should list all" do
    config = Global::Config.new(@path)
    config.set(:test1, "a")
    config.set(:test2, 1)
    config.set(:test3, true)
    config.save

    res = TestHelper::Command.succeed do
      Command::PioneConfig.run(["--list", "-f", @path.to_s])
    end

    list = res.stdout.string.split("\n")
    list.should.include("test1: a")
    list.should.include("test2: 1")
    list.should.include("test3: true")
  end

  it "should set items" do
    TestHelper::Command.succeed do
      Command::PioneConfig.run(["--set", "test1", "a", "-f", @path.to_s])
    end

    TestHelper::Command.succeed do
      Command::PioneConfig.run(["--set", "test2", "1", "-f", @path.to_s])
    end

    TestHelper::Command.succeed do
      Command::PioneConfig.run(["--set", "test3", "true", "-f", @path.to_s])
    end

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

    TestHelper::Command.succeed do
      Command::PioneConfig.run(["--unset", "test1", "-f", @path.to_s])
    end

    TestHelper::Command.succeed do
      Command::PioneConfig.run(["--unset", "test2", "-f", @path.to_s])
    end

    TestHelper::Command.succeed do
      Command::PioneConfig.run(["--unset", "test3", "-f", @path.to_s])
    end

    config = Global::Config.new(@path)
    config[:test1].should.nil
    config[:test2].should.nil
    config[:test3].should.nil
  end
end
