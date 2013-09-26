require 'pione/test-helper'

describe "Pione::System::DomainInfo" do
  before do
    @env = TestHelper::Lang.env
    TestHelper::Lang.declaration!(@env, "$A := 1")
    TestHelper::Lang.declaration!(@env, "$B := 1.23")
    TestHelper::Lang.declaration!(@env, "$C := $A")
    TestHelper::Lang.declaration!(@env, "$D := true")
    @location = Location[Temppath.create].tap do |location|
      System::DomainInfo.new(@env).write(location)
    end
  end

  it "should write a domain info file" do
    location = Location[Temppath.create]
    System::DomainInfo.new(@env).write(location)
    location.should.exist
  end

  it "should read a domain info file" do
    env = System::DomainInfo.read(@location).env
    env.variable_get(Lang::Variable.new("A")).should == TestHelper::Lang.expr("1")
    env.variable_get(Lang::Variable.new("B")).should == TestHelper::Lang.expr("1.23")
    env.variable_get(Lang::Variable.new("C")).should == TestHelper::Lang.expr("1")
    env.variable_get(Lang::Variable.new("D")).should == TestHelper::Lang.expr("true")
  end
end

