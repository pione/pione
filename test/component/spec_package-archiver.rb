require_relative '../test-util'

describe "Pione::Component::PackageArchiver" do
  before do
    @path = TestUtil::Package.get("TestPackage1")
  end

  it "should create archive file" do
    out = Location[Temppath.mkdir]
    Component::PackageArchiver.new(@path).archive(out)

    # easy check
    pkg = out + "TestPackage1+v0.1.0.ppg"
    pkg.should.exist
    pkg.should.file
    pkg.size.should > 0

    # structure check
    Zip::Archive.open(pkg.path.to_s) do |ar|
      ar.each do |file|
        unless file.directory?
          file.read.should == (@path + file.name).read
        end
      end
    end
  end
end
