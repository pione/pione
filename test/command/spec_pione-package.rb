require 'pione/test-helper'

describe "Pione::Command::PionePackage" do
  it "should build PIONE package" do
    package_location = Location[File.dirname(__FILE__)] + ".." + "package" + "data" + "TestPackage1"
    output_location = Location[Temppath.mkdir]
    res = TestHelper::Command.succeed do
      Command::PionePackage.run ["--build", "-o", output_location.path.to_s, package_location.path.to_s]
    end
    pkg = output_location + "TestPackage1+v0.1.0.ppg"
    pkg.should.exist
    pkg.size.should > 0
  end
end

