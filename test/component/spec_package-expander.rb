require_relative '../test-util'

describe "Pione::Component::PackageExpander" do
  it "should expand archive package" do
    location = TestUtil::TEST_PACKAGE_DIR + "TestPackage1+v0.1.0.ppg"
    expanded = Location[Temppath.mkdir]
    Component::PackageExpander.new(location).expand(expanded)
    (expanded + "package.yml").should.exist
  end
end

