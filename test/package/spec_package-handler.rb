require 'pione/test-helper'

TestHelper.scope do |this|
  this::PACKAGE_DIR = Location[File.dirname(__FILE__)] + "data"

  describe Pione::Package::PackageHandler do
    before do
      @env = TestHelper::Lang.env
      @location = this::PACKAGE_DIR + "TestPackage1"
      @handler = Package::PackageReader.read(@location)
      @case1 = @handler.info.scenarios[0]
      @case2 = @handler.info.scenarios[1]
      @case3 = @handler.info.scenarios[2]
    end

    it "should get the package name" do
      @handler.info.name.should == "TestPackage1"
    end

    it "should get bin" do
      @handler.info.bins.should == ["bin/count"]
    end

    it "should get scenarios" do
      @handler.info.scenarios.should.include "scenario/case1"
      @handler.info.scenarios.should.include "scenario/case2"
      @handler.info.scenarios.should.include "scenario/case3"
    end

    it "should get rules" do
      env = @handler.eval(@env)
      env.rule_get(Lang::RuleExpr.new(package_id: env.current_package_id, name: "Main")).should.kind_of(Lang::RuleDefinition)
      env.rule_get(Lang::RuleExpr.new(package_id: env.current_package_id, name: "Count")).should.kind_of(Lang::RuleDefinition)
    end

    it "should upload package files" do
      location = Location[Temppath.create]
      @handler.upload(location)
      location.directory_entries.should.include(location + "bin")
      (location + "bin").file_entries.should.include(location + "bin" + "count")
    end

    it "should find sceinarios" do
      @handler.find_scenario(:anything).info.name.should == "Case1"
      @handler.find_scenario("Case1").info.name.should == "Case1"
      @handler.find_scenario("Case2").info.name.should == "Case2"
      @handler.find_scenario("Case3").info.name.should == "Case3"
    end
  end
end
