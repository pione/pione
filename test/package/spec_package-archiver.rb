require 'pione/test-helper'

TestHelper.scope do |this|
  this::PACKAGE_DIR = Location[File.dirname(__FILE__)] + "data"

  describe "Pione::Package::PackageArchiver" do
    before do
      @path = this::PACKAGE_DIR + "TestPackage1"
    end

    it "should create archive file" do
      out = Location[Temppath.mkdir]
      Package::PackageArchiver.new(@path).archive(out, false)

      # easy check
      pkg = out + "TestPackage1+v0.1.0.ppg"
      pkg.should.exist
      pkg.should.file
      pkg.size.should > 0

      # structure check
      Zip::File.open(pkg.path.to_s) do |zip|
        zip.each do |entry|
          unless entry.directory? or entry.name == ".digest"
            zip.file.open(entry.name).read.should == (@path + entry.name).read
          end
        end
      end
    end
  end
end
