require_relative '../test-util'

describe "Pione::Component::Package" do
  before do
    @env = TestUtil::Lang.env
    @location = TestUtil::Package.get("TestPackage1")
    @package = Component::PackageReader.read(@location)
    @case1 = @package.scenarios[0]
    @case2 = @package.scenarios[1]
    @case3 = @package.scenarios[2]
  end

  it "should equal" do
    Component::Package.new(location: @location, info: {"PackageName1" => "Test"}).should ==
      Component::Package.new(location: @location, info: {"PackageName1" => "Test"})
  end

  it "should not equal" do
    Component::Package.new(location: @location, info: {"PackageName1" => "Test1"}).should !=
      Component::Package.new(location: @location, info: {"PackageName1" => "Test2"})
  end

  it "should get the package name" do
    @package.name.should == "TestPackage1"
  end

  it "should get bin" do
    @package.bin.should.directory
  end

  it "should get scenarios" do
    names = @package.scenarios.map{|scenario| scenario.name}
    names.should.include "Case1"
    names.should.include "Case2"
    names.should.include "Case3"
  end

  it "should get the context" do
    @package.context.should.kind_of(Lang::PackageContext)
    @package.context.elements.size.should > 0
  end

  it "should get rules" do
    package_id = @package.eval(@env)
    @env.rule_get(RuleExpr.new(package_id: package_id, name: "Main")).should.kind_of(Lang::RuleDefinition)
    @env.rule_get(RuleExpr.new(package_id: package_id, name: "Count")).should.kind_of(Lang::RuleDefinition)
  end

  it "should upload package files" do
    location = Location[Temppath.create]
    @package.upload(location)
    location.directory_entries.should.include(location + @package.name)
    (location + @package.name + "bin").file_entries.should.include(location + @package.name + "bin" + "count")
  end

  it "should find sceinarios" do
    @package.find_scenario(:anything).name.should == "Case1"
    @package.find_scenario("Case1").name.should == "Case1"
    @package.find_scenario("Case2").name.should == "Case2"
    @package.find_scenario("Case3").name.should == "Case3"
  end
end

describe "Pione::Component::PackageScenario" do
  before do
    @location = TestUtil::Package.get("TestPackage1")
    @case1 = Component::PackageScenarioReader.new(@location, "scenario/case1").read
    @case2 = Component::PackageScenarioReader.new(@location, "scenario/case2").read
    @case3 = Component::PackageScenarioReader.new(@location, "scenario/case3").read
  end

  it 'should equal' do
    Component::PackageScenario.new(@location, "scenario/case1", {"ScenarioName" => "Test"}).should ==
      Component::PackageScenario.new(@location, "scenario/case1", {"ScenarioName" => "Test"})
  end

  it 'should not equal' do
    Component::PackageScenario.new(@location, "scenario/case1", {"ScenarioName" => "Test1"}).should !=
      Component::PackageScenario.new(@path, "scenario/case1", {"ScenarioName" => "Test2"})
  end

  it "should get the scenario name" do
    @case1.name.should == "Case1"
    @case2.name.should == "Case2"
    @case3.name.should == "Case3"
  end

  it "should get input files" do
    @case1.inputs[0].basename.should == "1.txt"
    @case2.inputs[0].basename.should == "1.txt"
    @case2.inputs[1].basename.should == "2.txt"
    @case2.inputs[2].basename.should == "3.txt"
    @case3.inputs[0].basename.should == "a.txt"
    @case3.inputs[1].basename.should == "b.txt"
  end

  it "should get output files" do
    @case1.outputs[0].basename.should == "1.count"
    @case2.outputs[0].basename.should == "1.count"
    @case2.outputs[1].basename.should == "2.count"
    @case2.outputs[2].basename.should == "3.count"
    @case3.outputs[0].basename.should == "a.count"
    @case3.outputs[1].basename.should == "b.count"
  end
end

