require 'pione/test-helper'

$stdout = STDOUT
$stderr = STDERR

TestHelper.scope do |this|
  this::PACKAGE_DIR = Location[File.dirname(__FILE__)] + "data"

  describe "Pione::Package::PackageReader" do
    shared "package" do
      it "should read the package and return it" do
        Package::PackageReader.read(@location).should.kind_of Package::Package
      end

      it "should get package informations" do
        package = Package::PackageReader.read(@location)
        package.name.should == "HelloWorld"
      end

      it "should get scenarios" do
        package = Package::PackageReader.read(@location)
        package.name.should == "HelloWorld"
        scenario = package.scenarios[0]
        scenario.name.should == "HelloWorld"
        scenario.inputs.should.empty
        scenario.outputs[0].basename.should == "message.txt"

        # case1 = package.scenarios[0]
        # case1.name.should == "Case1"
        # case1.inputs[0].basename.should == "1.txt"
        # case2 = package.scenarios[1]
        # case2.name.should == "Case2"
        # case2.inputs[0].basename.should == "1.txt"
        # case2.inputs[1].basename.should == "2.txt"
        # case2.inputs[2].basename.should == "3.txt"
        # case3 = package.scenarios[2]
        # case3.name.should == "Case3"
        # case3.inputs[0].basename.should == "a.txt"
        # case3.inputs[1].basename.should == "b.txt"
      end
    end

    shared "directory package" do
      it "should read package directory" do
        Package::PackageReader.new(@location).type.should == :directory
      end
    end

    describe "directory package at local location" do
      before do
        @env = TestHelper::Lang.env
        @location = this::PACKAGE_DIR + "HelloWorld"
      end

      behaves_like "package"
      behaves_like "directory package"
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
      behaves_like "directory package"
    end

    describe "archive package at local location" do
      before do
        @env = TestHelper::Lang.env
        @location = this::PACKAGE_DIR + "HelloWorld+v0.1.0.ppg"
      end

      behaves_like "package"
    end

    describe "archive package at HTTP location" do
      before do
        @env = TestHelper::Lang.env
        @server = TestHelper::WebServer.start(this::PACKAGE_DIR)
        @location = @server.root + "HelloWorld+v0.1.0.ppg"
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
