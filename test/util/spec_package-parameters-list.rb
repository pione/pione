require_relative '../test-util'

describe "Pione::Util::PackageParametersList" do
  before do
    @dir = Location[File.dirname(__FILE__)]
  end

  after do
    $stdout = STDOUT
  end

  it "should print parameters list of the package: 1" do
    pkg = Component::PackageReader.read(@dir + "spec_package-parameters-list_1.pione")
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(pkg)
    $stdout = STDOUT
    stdout.string.should.include("Basic Parameters")
    stdout.string.should.include("Advanced Parameters")
    stdout.string.should.include("A :=")
    stdout.string.should.include("B :=")
    stdout.string.should.include("C :=")
    stdout.string.should.include("D :=")
  end

  it "should print parameters list of the package: 2" do
    pkg = Component::PackageReader.read(@dir + "spec_package-parameters-list_2.pione")
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(pkg)
    $stdout = STDOUT
    stdout.string.should.include("Basic Parameters")
    stdout.string.should.not.include("Advanced Parameters")
    stdout.string.should.include("A :=")
    stdout.string.should.include("B :=")
  end

  it "should print parameters list of the package: 3" do
    pkg = Component::PackageReader.read(@dir + "spec_package-parameters-list_3.pione")
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(pkg)
    $stdout = STDOUT
    stdout.string.should.not.include("Basic Parameters")
    stdout.string.should.include("Advanced Parameters")
    stdout.string.should.include("A :=")
    stdout.string.should.include("B :=")
  end

  it "should print no parameters message" do
    pkg = Component::PackageReader.read(@dir + "spec_package-parameters-list_4.pione")
    stdout = StringIO.new("", "w")
    $stdout = stdout
    Util::PackageParametersList.print(pkg)
    $stdout = STDOUT
    stdout.string.should.not.include("Basic Parameters")
    stdout.string.should.not.include("Advanced Parameters")
  end
end
