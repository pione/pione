require 'pione/test-helper'
require_relative 'command-behavior'

TestHelper.scope do |this|
  def this::days_before(n)
    (Date.today - n).to_time
  end

  class this::FakeFileSet
    include TestHelper.scope_of(self)

    def initialize
      @files = Hash.new {|h, k| h[k] = []}
      make_temporary_files
      make_file_cache_files
      make_package_cache_files
      make_profile_files
    end

    def make_temporary_files
      dir1 = Location[Global.my_temporary_directory] + Util::UUID.generate
      make_file(:temporary, dir1 + "a", 30)
      make_file(:temporary, dir1 + "b", 1)
      make_file(:temporary, dir1 + "c" + "c", 30)
      make_file(:temporary, dir1 + "d" + "d", 1)
      dir1.mtime = this.days_before(30)
      dir2 = Location[Global.my_temporary_directory] + Util::UUID.generate
      make_file(:temporary, dir2 + "a", 30)
      make_file(:temporary, dir2 + "b", 1)
      make_file(:temporary, dir2 + "c" + "c", 30)
      make_file(:temporary, dir2 + "d" + "d", 1)
      dir2.mtime = this.days_before(1)
    end

    def make_file_cache_files
      dir1 = Location[Global.my_file_cache_directory] + Util::UUID.generate
      make_file(:file_cache, dir1 + "a", 30)
      make_file(:file_cache, dir1 + "b", 1)
      dir1.mtime = this.days_before(30)
      dir2 = Location[Global.my_file_cache_directory] + Util::UUID.generate
      make_file(:file_cache, dir2 + "a", 30)
      make_file(:file_cache, dir2 + "b", 1)
      dir2.mtime = this.days_before(1)
    end

    def make_package_cache_files
      ppg = Global.ppg_package_cache_directory
      make_file(:package_cache, ppg + "a", 30)
      make_file(:package_cache, ppg + "b", 1)
      dir = Global.directory_package_cache_directory
      make_file(:package_cache, dir + "a", 30)
      make_file(:package_cache, dir + "b", 1)
    end

    def make_profile_files
      profile = Location[Global.profile_report_directory]
      make_file(:profile, profile + "a", 30)
      make_file(:profile, profile + "b", 1)
    end

    def temporary
      @files[:temporary].select {|f| f.exist?}
    end

    def file_cache
      @files[:file_cache].select {|f| f.exist?}
    end

    def package_cache
      @files[:package_cache].select {|f| f.exist?}
    end

    def profile
      @files[:profile].select {|f| f.exist?}
    end

    private

    def make_file(type, location, days)
      @files[type] << location
      location.write("")
      location.mtime = this.days_before(days).to_time
    end
  end

  describe Pione::Command::PioneClean do
    before do
      @cmd = Pione::Command::PioneClean
      @orig_my_temporary_directory = Global.my_temporary_directory
      Global.my_temporary_directory = Temppath.mkdir
      @orig_file_cache_directory = Global.my_file_cache_directory
      Global.my_file_cache_directory = Temppath.mkdir
      @orig_ppg_package_cache_directory = Global.ppg_package_cache_directory
      Global.ppg_package_cache_directory = Temppath.mkdir
      @orig_directory_package_cache_directory = Global.directory_package_cache_directory
      Global.directory_package_cache_directory = Temppath.mkdir
      @orig_profile_report_directory = Global.profile_report_directory
      Global.profile_report_directory = Temppath.mkdir
    end

    after do
      Global.my_temporary_directory = @orig_my_temporary_directory
      Global.my_file_cache_directory = @orig_my_file_cache_directory
      Global.ppg_package_cache_directory = @orig_ppg_package_cache_directory
      Global.directory_package_cache_directory = @orig_directory_package_cache_directory
      Global.profile_report_directory = @orig_profile_report_directory
    end

    behaves_like "command"

    it "should remove all type files" do
      fset = this::FakeFileSet.new
      Rootage::ScenarioTest.succeed(@cmd.new([]))
      fset.temporary.size.should == 0
      fset.file_cache.size.should == 0
      fset.package_cache.size.should == 0
      fset.profile.size.should == 0
    end

    it "should remove older files than 1 days" do
      fset = this::FakeFileSet.new
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", "1"]))
      fset.temporary.size.should == 0
      fset.file_cache.size.should == 0
      fset.package_cache.size.should == 0
      fset.profile.size.should == 0
    end

    it "should remove older files than 2 days" do
      fset = this::FakeFileSet.new
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", "2"]))
      fset.temporary.size.should == 4
      fset.file_cache.size.should == 2
      fset.package_cache.size.should == 2
      fset.profile.size.should == 1
    end

    it "should remove older files than 30 days" do
      fset = this::FakeFileSet.new
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", "30"]))
      fset.temporary.size.should == 4
      fset.file_cache.size.should == 2
      fset.package_cache.size.should == 2
      fset.profile.size.should == 1
    end

    it "should remove older files than 31 days" do
      fset = this::FakeFileSet.new
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", "31"]))
      fset.temporary.size.should == 8
      fset.file_cache.size.should == 4
      fset.package_cache.size.should == 4
      fset.profile.size.should == 2
    end

    it "should remove older files than 1 days with iso8601 format" do
      fset = this::FakeFileSet.new
      date = this.days_before(1)
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", date.iso8601]))
      fset.temporary.size.should == 0
      fset.file_cache.size.should == 0
      fset.package_cache.size.should == 0
      fset.profile.size.should == 0
    end

    it "should remove older files than 2 days with iso8601 format" do
      fset = this::FakeFileSet.new
      date = this.days_before(2)
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", date.iso8601]))
      fset.temporary.size.should == 4
      fset.file_cache.size.should == 2
      fset.package_cache.size.should == 2
      fset.profile.size.should == 1
    end

    it "should remove older files than 30 days with iso8601 format" do
      fset = this::FakeFileSet.new
      date = this.days_before(30)
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", date.iso8601]))
      fset.temporary.size.should == 4
      fset.file_cache.size.should == 2
      fset.package_cache.size.should == 2
      fset.profile.size.should == 1
    end

    it "should remove older files than 31 days with iso8601 format" do
      fset = this::FakeFileSet.new
      date = this.days_before(31)
      Rootage::ScenarioTest.succeed(@cmd.new(["--older", date.iso8601]))
      fset.temporary.size.should == 8
      fset.file_cache.size.should == 4
      fset.package_cache.size.should == 4
      fset.profile.size.should == 2
    end

    it "should remove temporary files" do
      Rootage::ScenarioTest.succeed(@cmd, ["--type", "temporary"]) do |cmd, args|
        fset = this::FakeFileSet.new
        cmd.run(args)
        fset.temporary.size.should == 0
        fset.file_cache.size.should == 4
        fset.package_cache.size.should == 4
        fset.profile.size.should == 2
      end
    end

    it "should remove file cache files" do
      Rootage::ScenarioTest.succeed(@cmd, ["--type", "file-cache"]) do |cmd, args|
        fset = this::FakeFileSet.new
        cmd.run(args)
        fset.temporary.size.should == 8
        fset.file_cache.size.should == 0
        fset.package_cache.size.should == 4
        fset.profile.size.should == 2
      end
    end

    it "should remove package cache files" do
      Rootage::ScenarioTest.succeed(@cmd, ["--type", "package-cache"]) do |cmd, args|
        fset = this::FakeFileSet.new
        cmd.run(args)
        fset.temporary.size.should == 8
        fset.file_cache.size.should == 4
        fset.package_cache.size.should == 0
        fset.profile.size.should == 2
      end
    end

    it "should remove profile files" do
      Rootage::ScenarioTest.succeed(@cmd, ["--type", "profile"]) do |cmd, args|
        fset = this::FakeFileSet.new
        cmd.run(args)
        fset.temporary.size.should == 8
        fset.file_cache.size.should == 4
        fset.package_cache.size.should == 4
        fset.profile.size.should == 0
      end
    end
  end
end
