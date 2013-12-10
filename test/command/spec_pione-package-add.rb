require 'pione/test-helper'

TestHelper.scope do |this|
  this::P1 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP1"
  this::P2 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP2"
  this::P3 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP3"
  this::P4 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP4"

  describe Pione::Command::PionePackage do
    before do
      @cmd = Pione::Command::PionePackageAdd
      @orig_database = Global.package_database_location
      Global.package_database_location = Location[Temppath.create]
    end

    after do
      Global.package_database_location = @orig_database
    end

    it "should add package with name to database" do
      TestHelper::Command.succeed(@cmd, [this::P1.path.to_s])
      db = Package::Database.load
      digest = db.find("P1", nil, nil)
      digest.size.should > 0
    end

    it "should add package with tag to database" do
      res = TestHelper::Command.succeed(@cmd, [this::P2.path.to_s])
      db = Package::Database.load
      digest = db.find("P2", nil, "v0.1.0")
      digest.size.should > 0
    end

    it "should add package with editor to database" do
      res = TestHelper::Command.succeed(@cmd, [this::P3.path.to_s])
      db = Package::Database.load
      digest = db.find("P3", "keita.yamaguchi@gmail.com", nil)
      digest.size.should > 0
    end

    it "should add package with full name to database" do
      TestHelper::Command.succeed(@cmd, [this::P4.path.to_s])
      db = Package::Database.load
      digest = db.find("P4", "keita.yamaguchi@gmail.com", "v0.1.0")
      digest.size.should > 0
    end

    it "should add tag alias" do
      TestHelper::Command.succeed(@cmd, ["--tag", "TEST", this::P4.path.to_s])
      db = Package::Database.load
      digest = db.find("P4", "keita.yamaguchi@gmail.com", "TEST")
      digest.size.should > 0
    end
  end
end
