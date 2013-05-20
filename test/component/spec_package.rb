require_relative '../test-util'

describe "Pione::Component::Package" do
  before do
    path = Location[File.expand_path("../spec_package", __FILE__)] + "TestPackage"
    @package = Component::PackageReader.new(path).read
    @scenario1 = @package.scenarios[0]
  end

  it "should equal" do
    Component::Package.new({"PackageName" => "Test"}, [], [], []).should ==
      Component::Package.new({"PackageName" => "Test"}, [], [], [])
  end

  it "should not equal" do
    Component::Package.new({"PackageName" => "Test1"}, [], [], []).should !=
      Component::Package.new({"PackageName" => "Test2"}, [], [], [])
  end

  it "should get the package name" do
    @package.name.should == "TestPackage"
  end

  it "should get bin" do
    @package.bin.should.directory
  end

  it "should get scenarios" do
    @package.scenarios.map{|scenario| scenario.name}.should.include "TestCase1"
  end

  it "should get docuemtns" do
    @package.documents.size.should == 1
  end

  it "should get rules" do
    @package.rules.keys.should.include("&TestPackage:Main")
    @package.rules.keys.should.include("&TestPackage:Count")
  end

  it "should get a main rule" do
    @package.main.rule_path.should == "&TestPackage:Main"
  end

  it "should upload package files" do
    location = Location[Temppath.create]
    @package.upload(location)
    location.directory_entries.should.include(location + @package.name)
    (location + @package.name + "bin").file_entries.should.include(location + @package.name + "bin" + "count")
  end
end

describe "Pione::Component::PackageScenario" do
  before do
    path = Location[File.expand_path("../spec_package", __FILE__)] + "TestPackage" + "scenario" + "case1"
    @scenario = Component::PackageScenarioReader.new(path).read
  end

  it 'should equal' do
    Component::PackageScenario.new({"ScenarioName" => "Test"}, [], []).should ==
      Component::PackageScenario.new({"ScenarioName" => "Test"}, [], [])
  end

  it 'should not equal' do
    Component::PackageScenario.new({"ScenarioName" => "Test1"}, [], []).should !=
      Component::PackageScenario.new({"ScenarioName" => "Test2"}, [], [])
  end

  it "should get the scenario name" do
    @scenario.name.should == "TestCase1"
  end
end
