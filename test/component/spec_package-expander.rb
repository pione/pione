require 'pione/test-helper'

TestHelper.scope do |this|
  this::PACKAGE_DIR = Location[File.dirname(__FILE__)] + "data"

  describe "Pione::Component::PackageExpander" do
    it "should expand archive package" do
      location = this::PACKAGE_DIR + "TestPackage1+v0.1.0.ppg"
      expanded = Location[Temppath.mkdir]
      Component::PackageExpander.new(location).expand(expanded)
      (expanded + "package.yml").should.exist
    end
  end
end
