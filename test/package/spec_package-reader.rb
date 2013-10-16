require 'pione/test-helper'

$stdout = STDOUT
$stderr = STDERR

TestHelper.scope do |this|
  this::PACKAGE_DIR = Location[File.dirname(__FILE__)] + "data"
  this::DIR_PACKAGE = this::PACKAGE_DIR + "HelloWorld"

  describe "Pione::Package::PackageReader" do
    shared "package" do
      it "should read the package and return the handler" do
        Package::PackageReader.read(@location).should.kind_of Package::PackageHandler
      end

      it "should get package informations" do
        handler = Package::PackageReader.read(@location)
        handler.info.name.should == "HelloWorld"
      end

      it "should get scenarios" do
        handler = Package::PackageReader.read(@location)
        handler.info.name.should == "HelloWorld"
        handler.info.scenarios == ["scenario"]
      end
    end

    describe "directory package at local location" do
      before do
        @env = TestHelper::Lang.env
        @location = this::PACKAGE_DIR + "HelloWorld"
      end

      behaves_like "package"
    end

    describe "directory package at HTTP location" do
      before do
        @env = TestHelper::Lang.env
        @server = TestHelper::WebServer.start(this::PACKAGE_DIR)
        @location = @server.root + "HelloWorld/"
      end

      after do
        @server.terminate
      end

      behaves_like "package"
    end

    describe "archive package at local location" do
      before do
        @env = TestHelper::Lang.env
        @location = this::PACKAGE_DIR + "HelloWorld+v0.1.1.ppg"
      end

      behaves_like "package"
    end

    describe "archive package at HTTP location" do
      before do
        @env = TestHelper::Lang.env
        @server = TestHelper::WebServer.start(this::PACKAGE_DIR)
        @location = @server.root + "HelloWorld+v0.1.1.ppg"
      end

      after do
        @server.terminate
      end

      behaves_like "package"
    end

    describe "git package at local location" do
      before do
        @env = TestHelper::Lang.env
        path = Temppath.mkdir
        Util::Zip.uncompress(this::PACKAGE_DIR + "HelloWorld-gitrepos.zip", Location[path])
        @location = Location[git: path]
      end

      behaves_like "package"
    end
  end
end
