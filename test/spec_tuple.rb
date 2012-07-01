require_relative 'test-util'

describe "Tuple" do
  describe "Tuple::TupleObject" do
    before do
      # test type tuple for this test
      Tuple.define_format([:test, :attr1, :attr2, :attr3])
    end

    after do
      Tuple.delete_format(:test)
    end

    it "should get a class for tuple object" do
      Tuple[:test].should.not.be.nil
      Tuple[:test].should == Tuple::Test
      Tuple[:test].ancestors.should.include Tuple::TupleObject
    end

    it "should get a tuple object" do
      t1 = Tuple[:test].new(attr1: 1, attr2: 2, attr3: 3)
      t2 = Tuple[:test].new(attr1: 3, attr2: 2, attr3: 1)
      t3 = Tuple[:test].new(attr2: 2, attr3: 3, attr1: 1)
      t4 = Tuple[:test].new(1, 2, 3)
      t5 = Tuple[:test].new(3, 2, 1)
      [t1, t2, t3, t4, t5].each {|t| t.should.be.kind_of? Tuple[:test]}
      t1.should.not == t2
      t1.should == t3
      t1.should == t4
      t1.should.not == t5
      t2.should.not == t3
      t2.should.not == t4
      t2.should == t5
      t3.should == t4
      t3.should.not == t5
      t4.should.not == t5
    end

    it "should get values of tuple objects" do
      t1 = Tuple[:test].new(attr1: 1, attr2: :a, attr3: true)
      t1.attr1.should == 1
      t1.attr2.should == :a
      t1.attr3.should == true
      t2 = Tuple[:test].new(attr1: 2, attr3: false)
      t2.attr1.should == 2
      t2.attr2.should.be.nil
      t2.attr3.should == false
    end

    it "should set new data in each field" do
      t = Tuple[:test].new(attr1: 1, attr2: :a, attr3: true)
      t.attr1 = 2
      t.attr2 = :b
      t.attr3 = false
      t.attr1.should.equal 2
      t.attr2.should.equal :b
      t.attr3.should.equal false
    end

    it "should get any form" do
      any = Tuple[:test].any
      any.should == Tuple[:test].new
      any.attr1.should.be.nil
      any.attr2.should.be.nil
      any.attr3.should.be.nil
    end

    it "should get tuple object from array" do
      t = Tuple.from_array([:test, 1, :a, true])
      t.should.be.kind_of Tuple::Test
      t.attr1.should.== 1
      t.attr2.should.== :a
      t.attr3.should.== true
      t.should.== Tuple[:test].new(attr1: 1, attr2: :a, attr3: true)
    end

    it "should raise exception when tuple is redefined by different format" do
      # different format
      should.raise(ArgumentError) do
        Tuple.define_format([:test, :attr3, :attr2, :attr1])
      end
      # same format
      should.not.raise(ArgumentError) do
        Tuple.define_format([:test, :attr1, :attr2, :attr3])
      end
    end
  end
end
