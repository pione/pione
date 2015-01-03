require 'pione/test-helper'

describe "Pione::Lang::PioneMethod" do
  before do
    @env = TestHelper::Lang.env
    @int_1 = Lang::IntegerSequence.of(1)
    @int_2 = Lang::IntegerSequence.of(2)
    @int_3 = Lang::IntegerSequence.of(3)
    @str_1 = Lang::StringSequence.of(1)
    @method_1 = Lang::PioneMethod.new(:immediate, "m1", [Lang::TypeInteger], Lang::TypeInteger, lambda{|env, rec, arg1| arg1})
    @method_2 = Lang::PioneMethod.new(:immediate, "m2", [Lang::TypeInteger, Lang::TypeString], Lang::TypeInteger, lambda{|env, rec, arg1, arg2| arg1})
    @method_3 = Lang::PioneMethod.new(:immediate, "m3", [], :receiver_type, lambda{|env, rec| rec})
    @method_bad = Lang::PioneMethod.new(:immediate, "mbad", [Lang::TypeString], Lang::TypeInteger, lambda{|env, rec, arg1| arg1})
  end

  it "should get inputs" do
    @method_1.inputs.should == [Lang::TypeInteger]
    @method_2.inputs.should == [Lang::TypeInteger, Lang::TypeString]
    @method_3.inputs.should == []
    @method_bad.inputs.should == [Lang::TypeString]
  end

  it "should get output" do
    @method_1.output.should == Lang::TypeInteger
    @method_2.output.should == Lang::TypeInteger
    @method_3.output.should == :receiver_type
    @method_bad.output.should == Lang::TypeInteger
  end

  it "should be callable" do
    @method_1.call(@env, @int_1, [@int_2]).should == @int_2
    @method_2.call(@env, @int_1, [@int_2, @str_1]).should == @int_2
    @method_3.call(@env, @int_1, []).should == @int_1
    @method_3.call(@env, @str_1, []).should == @str_1
  end

  it "should validate inputs" do
    env = Lang::Environment.new
    @method_1.validate_inputs(env, @int_1, []).should.be.false
    @method_2.validate_inputs(env, @int_1, []).should.be.false
    @method_2.validate_inputs(env, @int_1, [@str_1]).should.be.false
    @method_2.validate_inputs(env, @int_1, [@int_2]).should.be.false
    @method_2.validate_inputs(env, @int_1, [@int_2, @int_3, @str_1]).should.be.false
    @method_3.validate_inputs(env, @int_1, [@int_2]).should.be.false
  end

  it "should call" do
    @method_1.call(@env, @int_1, [@int_2]).should == @int_2
    @method_2.call(@env, @int_1, [@int_2, @str_1]).should == @int_2
    @method_3.call(@env, @int_1, []).should == @int_1
  end

  it "should raise interface error" do
    should.raise(Lang::MethodInterfaceError){ @method_1.call(@env, @int_1, [@str_1]) }
    should.raise(Lang::MethodInterfaceError){ @method_2.call(@env, @int_1, [@str_1, @str_1]) }
    should.raise(Lang::MethodInterfaceError){ @method_bad.call(@env, @int_1, [@str_1]) }
  end
end
