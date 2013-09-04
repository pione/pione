require_relative '../test-util'

describe "Pione::Model::PioneMethod" do
  before do
    @env = TestUtil::Lang.env
    @int_1 = IntegerSequence.of(1)
    @int_2 = IntegerSequence.of(2)
    @int_3 = IntegerSequence.of(3)
    @str_1 = StringSequence.of(1)
    @method_1 = Model::PioneMethod.new(:immediate, "m1", [TypeInteger], TypeInteger, lambda{|env, rec, arg1| arg1})
    @method_2 = Model::PioneMethod.new(:immediate, "m2", [TypeInteger, TypeString], TypeInteger, lambda{|env, rec, arg1, arg2| arg1})
    @method_3 = Model::PioneMethod.new(:immediate, "m3", [], :receiver_type, lambda{|env, rec| rec})
    @method_bad = Model::PioneMethod.new(:immediate, "mbad", [TypeString], TypeInteger, lambda{|env, rec, arg1| arg1})
  end

  it "should get inputs" do
    @method_1.inputs.should == [TypeInteger]
    @method_2.inputs.should == [TypeInteger, TypeString]
    @method_3.inputs.should == []
    @method_bad.inputs.should == [TypeString]
  end

  it "should get output" do
    @method_1.output.should == TypeInteger
    @method_2.output.should == TypeInteger
    @method_3.output.should == :receiver_type
    @method_bad.output.should == TypeInteger
  end

  it "should be callable" do
    @method_1.call(@env, @int_1, [@int_2]).should == @int_2
    @method_2.call(@env, @int_1, [@int_2, @str_1]).should == @int_2
    @method_3.call(@env, @int_1, []).should == @int_1
    @method_3.call(@env, @str_1, []).should == @str_1
  end

  it "should validate inputs" do
    @method_1.validate_inputs(@int_1, []).should.be.false
    @method_2.validate_inputs(@int_1, []).should.be.false
    @method_2.validate_inputs(@int_1, [@str_1]).should.be.false
    @method_2.validate_inputs(@int_1, [@int_2]).should.be.false
    @method_2.validate_inputs(@int_1, [@int_2, @int_3, @str_1]).should.be.false
    @method_3.validate_inputs(@int_1, [@int_2]).should.be.false
  end

  it "should call" do
    @method_1.call(@env, @int_1, [@int_2]).should == @int_2
    @method_2.call(@env, @int_1, [@int_2, @str_1]).should == @int_2
    @method_3.call(@env, @int_1, []).should == @int_1
  end

  it "should raise interface error" do
    should.raise(MethodInterfaceError){ @method_1.call(@env, @int_1, [@str_1]) }
    should.raise(MethodInterfaceError){ @method_2.call(@env, @int_1, [@str_1, @str_1]) }
    should.raise(MethodInterfaceError){ @method_bad.call(@env, @int_1, [@str_1]) }
  end
end
