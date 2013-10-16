require 'pione/test-helper'

TestHelper.scope do |this|
  this::P1 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP1"
  this::P2 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP2"
  this::P3 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP3"
  this::P4 = Location[File.dirname(__FILE__)] + ".." + "command" + "data" + "PionePackageP4"

  describe "Pione::Command::PionePackage" do
    before do
      @orig_database = Global.package_database_location
      Global.package_database_location = Location[Temppath.create]
    end

    after do
      Global.package_database_location = @orig_database
    end

    it "should build PIONE package with the package name" do
      output_location = Location[Temppath.mkdir]
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--build", "-o", output_location.path.to_s, this::P1.path.to_s]
      end
      pkg = output_location + "P1.ppg"
      pkg.should.exist
      pkg.size.should > 0
    end

    it "should build PIONE package with the tag" do
      output_location = Location[Temppath.mkdir]
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--build", "-o", output_location.path.to_s, this::P2.path.to_s]
      end
      pkg = output_location + "P2+v0.1.0.ppg"
      pkg.should.exist
      pkg.size.should > 0
    end

    it "should build PIONE package with the edition" do
      output_location = Location[Temppath.mkdir]
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--build", "-o", output_location.path.to_s, this::P3.path.to_s]
      end
      pkg = output_location + "P3(keita.yamaguchi@gmail.com).ppg"
      pkg.should.exist
      pkg.size.should > 0
    end

    it "should build PIONE package with full name" do
      output_location = Location[Temppath.mkdir]
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--build", "-o", output_location.path.to_s, this::P4.path.to_s]
      end
      pkg = output_location + "P4(keita.yamaguchi@gmail.com)+v0.1.0.ppg"
      pkg.should.exist
      pkg.size.should > 0
    end

    it "should add package with name to database" do
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--add", this::P1.path.to_s]
      end
      db = Package::Database.load
      digest = db.find("P1", nil, nil)
      digest.size.should > 0
    end

    it "should add package with tag to database" do
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--add", this::P2.path.to_s]
      end
      db = Package::Database.load
      digest = db.find("P2", nil, "v0.1.0")
      digest.size.should > 0
    end

    it "should add package with edition to database" do
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--add", this::P3.path.to_s]
      end
      db = Package::Database.load
      digest = db.find("P3", "keita.yamaguchi@gmail.com", nil)
      digest.size.should > 0
    end

    it "should add package with full name to database" do
      TestHelper::Command.succeed do
        Command::PionePackage.run ["--add", this::P4.path.to_s]
      end
      db = Package::Database.load
      digest = db.find("P4", "keita.yamaguchi@gmail.com", "v0.1.0")
      digest.size.should > 0
    end

    it "should write a package information file" do
      location = Location[Temppath.mkdir]
      (this::P1 + "P1.pione").copy(location + "P1.pione")
      res = TestHelper::Command.succeed do
        Command::PionePackage.run ["--write-info", location.path.to_s]
      end
      (location + "pione-package.json").should.exist
    end
  end
end

