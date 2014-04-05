require 'pione/test-helper'

describe Pione::System::DomainDump do
  before do
    @env = TestHelper::Lang.env
    TestHelper::Lang.declaration!(@env, "$A := 1")
    TestHelper::Lang.declaration!(@env, "$B := 1.23")
    TestHelper::Lang.declaration!(@env, "$C := $A")
    TestHelper::Lang.declaration!(@env, "$D := true")
    @location = Location[Temppath.create].tap do |location|
      System::DomainDump.new(@env).write(location)
    end
  end

  it "should write a domain dump" do
    location = Location[Temppath.create]
    System::DomainDump.new(@env).write(location)
    location.should.exist
  end

  it "should load a domain dump" do
    env = System::DomainDump.load(@location).env
    env.variable_get(Lang::Variable.new("A")).should == TestHelper::Lang.expr("1")
    env.variable_get(Lang::Variable.new("B")).should == TestHelper::Lang.expr("1.23")
    env.variable_get(Lang::Variable.new("C")).should == TestHelper::Lang.expr("1")
    env.variable_get(Lang::Variable.new("D")).should == TestHelper::Lang.expr("true")
  end
end

