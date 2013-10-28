require "pione/test-helper"

describe do
  it "should define an external item" do
    item = Global.define_external_item(:test_external_item) do |item|
      item.desc = "test external item"
      item.init = 1
      item.define_updater do |val|
        "value is %s" % val
      end
    end

    Global.test_external_item.should == "value is 1"
    Global.test_external_item = 2
    Global.test_external_item.should == "value is 2"

    item.unregister

    should.raise(NoMethodError) {Global.test_external_item}
  end

  it "should define an internal item" do
    item = Global.define_internal_item(:test_internal_item) do |item|
      item.desc = "test internal item"
      item.init = 1
      item.define_updater do |val|
        "value is %s" % val
      end
    end

    Global.test_internal_item.should == "value is 1"
    Global.test_internal_item = 2
    Global.test_internal_item.should == "value is 2"

    item.unregister

    should.raise(NoMethodError) {item.test_internal_item}
  end

  it "should define a computed item" do
    item1 = Global.define_external_item(:test_external_item) do |item|
      item.desc = "test external item"
      item.type = :integer
      item.init = 1
      item.define_updater {|val| "external: %s" % val}
    end

    item2 = Global.define_internal_item(:test_internal_item) do |item|
      item.desc = "test internal item"
      item.type = :integer
      item.init = 2
      item.define_updater {|val| "internal: %s" % val}
    end

    item3 = item = Global.define_computed_item(:test_computed_item, [:test_external_item, :test_internal_item]) do |item|
      item.desc = "test computed item"
      item.define_updater do
        "%s, %s" % [Global.test_external_item, Global.test_internal_item]
      end
    end

    Global.test_computed_item.should == "external: 1, internal: 2"
    Global.test_external_item = 2
    Global.test_computed_item.should == "external: 2, internal: 2"
    Global.test_internal_item = 1
    Global.test_computed_item.should == "external: 2, internal: 1"
    Global.test_external_item = 3
    Global.test_internal_item = 4
    Global.test_computed_item.should == "external: 3, internal: 4"

    item1.unregister
    item2.unregister
    item3.unregister

    should.raise(NoMethodError) {item.test_computed_item}
  end
end
