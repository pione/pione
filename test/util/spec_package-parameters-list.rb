require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data" + "package-parameters-list"

  describe Pione::Util::PackageParametersList do
    it "should find parameters from `Param1.pione`" do
      env = Package::PackageReader.read(this::DIR + "Param1.pione").eval(Lang::Environment.new)
      basic, advanced = Util::PackageParametersList.find(env, env.current_package_id)
      basic.map{|param| param.name}.tap do |_basic|
        _basic.should.include "A"
        _basic.should.include "C"
      end
      advanced.map{|param| param.name}.tap do |_advanced|
        _advanced.should.include "B"
        _advanced.should.include "D"
      end
    end

    it "should find parameters from `Param2.pione`" do
      env = Package::PackageReader.read(this::DIR + "Param2.pione").eval(Lang::Environment.new)
      basic, advanced = Util::PackageParametersList.find(env, env.current_package_id)
      basic.map{|param| param.name}.tap do |_basic|
        _basic.should.include "A"
        _basic.should.include "B"
      end
      advanced.should.empty
    end

    it "should find parameters from `Param3.pione`" do
      env = Package::PackageReader.read(this::DIR + "Param3.pione").eval(Lang::Environment.new)
      basic, advanced = Util::PackageParametersList.find(env, env.current_package_id)
      basic.should.empty
      advanced.map{|param| param.name}.tap do |_advanced|
        _advanced.should.include "A"
        _advanced.should.include "B"
      end
    end

    it "should find parameters from `Param4.pione`" do
      env = Package::PackageReader.read(this::DIR + "Param4.pione").eval(Lang::Environment.new)
      basic, advanced = Util::PackageParametersList.find(env, env.current_package_id)
      basic.should.empty
      advanced.should.empty
    end
  end
end
