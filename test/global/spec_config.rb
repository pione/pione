require "pione/test-helper"

describe Pione::Global::Config do
  before do
    Global.define_external_item(:test)

    @path = Temppath.create
    @config = Global::Config.new(@path)
  end

  after do
    Global.item[:test].unregister
  end

  it "should set and get a item" do
    @config.set("test", "a")
    @config.get("test").should == "a"
  end

  it "should unset a item" do
    @config.set("test", "a")
    @config.unset("test")
    @config.get("test").should.nil
  end

  it "should save config file" do
    Global.define_external_item(:test1)
    Global.define_external_item(:test2)
    Global.define_external_item(:test3)

    # set
    @config.set("test1", "a")
    @config.set("test2", 1)
    @config.set("test3", true)

    # save
    @config.save

    # delete
    Global.item[:test1].unregister
    Global.item[:test2].unregister
    Global.item[:test3].unregister

    # test
    table = JSON.load(@path.read)
    table["test1"].should == "a"
    table["test2"].should == 1
    table["test3"].should.true
  end
end
