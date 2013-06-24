require_relative "../test-util"

describe "Pione::Command::PionePackage" do
  it "should build PIONE package" do
    package_location = TestUtil::Package.get("TestPackage1")
    output_location = Location[Temppath.mkdir]
    res = TestUtil::Command.succeed do
      Command::PionePackage.run ["--build", "-o", output_location.path.to_s, package_location.path.to_s]
    end
    pkg = output_location + "TestPackage-0.1.0.ppg"
    pkg.should.exist
    pkg.size.should > 0
  end

  it "should build PIONE package with name" do
    package_location = TestUtil::Package.get("TestPackage1")
    output_location = Location[Temppath.mkdir] + "Test.ppg"
    res = TestUtil::Command.succeed do
      Command::PionePackage.run ["--build", "-o", output_location.path.to_s, package_location.path.to_s]
    end
    pkg = output_location
    pkg.should.exist
    pkg.size.should > 0
  end
end

