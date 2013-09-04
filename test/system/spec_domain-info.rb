require_relative "../test-util"

describe "Pione::System::DomainInfo" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.declaration!(@env, "$A := 1")
    TestUtil::Lang.declaration!(@env, "$B := 1.23")
    TestUtil::Lang.declaration!(@env, "$C := $A")
    TestUtil::Lang.declaration!(@env, "$D := true")
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
    env.variable_get(Model::Variable.new("A")).should == TestUtil::Lang.expr("1")
    env.variable_get(Model::Variable.new("B")).should == TestUtil::Lang.expr("1.23")
    env.variable_get(Model::Variable.new("C")).should == TestUtil::Lang.expr("1")
    env.variable_get(Model::Variable.new("D")).should == TestUtil::Lang.expr("true")
  end
end

