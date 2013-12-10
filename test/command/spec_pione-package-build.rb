require 'pione/test-helper'

TestHelper.scope do |this|
  this::P1 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP1"
  this::P2 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP2"
  this::P3 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP3"
  this::P4 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP4"

  describe Pione::Command::PionePackageBuild do
    before do
      @cmd = Pione::Command::PionePackageBuild
      @orig_database = Global.package_database_location
      Global.package_database_location = Location[Temppath.create]
    end

    after do
      Global.package_database_location = @orig_database
    end

    it "should build PIONE package with the package name" do
      output_location = Location[Temppath.mkdir]
      args = ["-o", output_location.path.to_s, this::P1.path.to_s]
      res = TestHelper::Command.succeed(@cmd, args)
      pkg = output_location + "P1.ppg"
      pkg.should.exist
      pkg.size.should > 0
    end

    it "should build PIONE package with the tag" do
      output_location = Location[Temppath.mkdir]
      args = ["-o", output_location.path.to_s, this::P2.path.to_s]
      res = TestHelper::Command.succeed(@cmd, args)
      pkg = output_location + "P2+v0.1.0.ppg"
      pkg.should.exist
      pkg.size.should > 0
    end

    it "should build PIONE package with the editor" do
      output_location = Location[Temppath.mkdir]
      args = ["-o", output_location.path.to_s, this::P3.path.to_s]
      res = TestHelper::Command.succeed(@cmd, args)
      pkg = output_location + "P3(keita.yamaguchi@gmail.com).ppg"
      pkg.should.exist
      pkg.size.should > 0
    end

    it "should build PIONE package with full name" do
      output_location = Location[Temppath.mkdir]
      args = ["-o", output_location.path.to_s, this::P4.path.to_s]
      res = TestHelper::Command.succeed(@cmd, args)
      pkg = output_location + "P4(keita.yamaguchi@gmail.com)+v0.1.0.ppg"
      pkg.should.exist
      pkg.size.should > 0
    end
  end
end

