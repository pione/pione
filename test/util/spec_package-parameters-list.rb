require 'pione/test-helper'

describe "Pione::Util::PackageParametersList" do
  before do
    @dir = Location[File.dirname(__FILE__)]
    @env = TestHelper::Lang.env.setup_new_package("SpecPackageParametersList")
  end

  after do
    $stdout = STDOUT
  end

  it "should print parameters list of the package: 1" do
    package_id = Component::PackageReader.read(@dir + "spec_package-parameters-list_1.pione").eval(@env)
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(@env, package_id)
    $stdout = STDOUT
    stdout.string.should.include("Basic Parameters")
    stdout.string.should.include("Advanced Parameters")
    stdout.string.should.include("A :=")
    stdout.string.should.include("B :=")
    stdout.string.should.include("C :=")
    stdout.string.should.include("D :=")
  end

  it "should print parameters list of the package: 2" do
    package_id = Component::PackageReader.read(@dir + "spec_package-parameters-list_2.pione").eval(@env)
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(@env, package_id)
    $stdout = STDOUT
    stdout.string.should.include("Basic Parameters")
    stdout.string.should.not.include("Advanced Parameters")
    stdout.string.should.include("A :=")
    stdout.string.should.include("B :=")
  end

  it "should print parameters list of the package: 3" do
    package_id = Component::PackageReader.read(@dir + "spec_package-parameters-list_3.pione").eval(@env)
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(@env, package_id)
    $stdout = STDOUT
    stdout.string.should.not.include("Basic Parameters")
    stdout.string.should.include("Advanced Parameters")
    stdout.string.should.include("A :=")
    stdout.string.should.include("B :=")
  end

  it "should print no parameters message" do
    package_id = Component::PackageReader.read(@dir + "spec_package-parameters-list_4.pione").eval(@env)
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(@env, package_id)
    $stdout = STDOUT
    stdout.string.should.not.include("Basic Parameters")
    stdout.string.should.not.include("Advanced Parameters")
  end
end
