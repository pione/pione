require_relative "../test-util"

class VariableHolderA
  include Util::VariableHoldable
  include_variable true
end

class VariableHolderB
  include Util::VariableHoldable
  include_variable false
end

class VariableHolderC
  include Util::VariableHoldable
  hold_variable :a
  attr_accessor :a
end

class VariableHolderD
  include Util::VariableHoldable
  hold_variables :a, :b, :c
  attr_accessor :a
  attr_accessor :b
  attr_accessor :c
end

describe "Pione::Util::VariableHoldable" do
  describe "VariableHolderA" do
    it "should include variable" do
      VariableHolderA.new.should.include_variable
    end
  end

  describe "VariableHolderB" do
    it "should not include variable" do
      VariableHolderB.new.should.not.include_variable
    end
  end

  describe "VariableHolderC" do
    it "should include variable" do
      c = VariableHolderC.new
      c.a = VariableHolderA.new
      c.should.include_variable
    end

    it "should not include variable" do
      c = VariableHolderC.new
      c.should.not.include_variable
      c.a = VariableHolderB.new
      c.should.not.include_variable
    end
  end

  describe "VariableHolderD" do
    it "should include variable" do
      d = VariableHolderD.new
      d.a = VariableHolderA.new
      d.should.include_variable
    end

    it "should not include variable" do
      d = VariableHolderD.new
      d.should.not.include_variable
      d.a = VariableHolderB.new
      d.should.not.include_variable
    end
  end
end
