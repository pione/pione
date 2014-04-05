require 'pione/test-helper'

TestHelper.scope do |this|
  this::P1 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP1"
  this::P2 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP2"
  this::P3 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP3"
  this::P4 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP4"
  this::DIR = Location[File.dirname(__FILE__)] + "data" + "pione-list-param"

  describe Pione::Command::PionePackage do
    before do
      @cmd = Pione::Command::PionePackageShow
      @orig_database = Global.package_database_location
      Global.package_database_location = Location[Temppath.create]
    end

    after do
      Global.package_database_location = @orig_database
    end

    it "should show parameters list of the package" do
      res = Rootage::ScenarioTest.succeed(@cmd.new(["example/HelloWorld/HelloWorld.pione"]))
      res.stdout.string.size.should > 0
    end

    it "should show basic parameters" do
      cmd = @cmd.new([(this::DIR + "BasicParameters.pione").path.to_s])
      res = Rootage::ScenarioTest.succeed(cmd)
      out = res.stdout.string
      out.should.include "B1"
      out.should.include "B2"
      out.should.include "B3"
      out.should.include "I1"
      out.should.include "I2"
      out.should.include "S1"
      out.should.include "S2"
      out.should.include "D1"
      out.should.include "D2"
    end

    it "should show basic parameters only without `--advanced` option" do
      cmd = @cmd.new([(this::DIR + "AdvancedParameters.pione").path.to_s])
      res = Rootage::ScenarioTest.succeed(cmd)
      out = res.stdout.string
      out.should.include "B1"
      out.should.not.include "B2"
      out.should.not.include "B3"
      out.should.include "I1"
      out.should.not.include "I2"
      out.should.include "S1"
      out.should.not.include "S2"
      out.should.include "D1"
      out.should.not.include "D2"
    end

    it "should show advanced parameters with `--advanced` option" do
      cmd = @cmd.new([(this::DIR + "AdvancedParameters.pione").path.to_s, "--advanced"])
      res = Rootage::ScenarioTest.succeed(cmd)
      out = res.stdout.string
      out.should.include "B1"
      out.should.include "B2"
      out.should.include "B3"
      out.should.include "I1"
      out.should.include "I2"
      out.should.include "S1"
      out.should.include "S2"
      out.should.include "D1"
      out.should.include "D2"
    end
  end
end

