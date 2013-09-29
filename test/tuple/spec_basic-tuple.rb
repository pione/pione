require 'pione/test-helper'

TestHelper.scope do |this|
  class this::TestTuple < Pione::TupleSpace::BasicTuple
    define_format([:test,
        [:attr1, Integer],
        [:attr2, Symbol],
        [:attr3, Object]])
  end

  describe "Pione::TupleSpace::BasicTuple" do
    it "should get a tuple class" do
      this::TestTuple.should.not.be.nil
      TupleSpace[:test].should == this::TestTuple
      this::TestTuple.ancestors.should.include Pione::TupleSpace::BasicTuple
      this::TestTuple.format.should == [:test,
        [:attr1, Integer],
        [:attr2, Symbol],
        [:attr3, Object]
      ]
    end

    it "should get a tuple object" do
      t1 = this::TestTuple.new(attr1: 1, attr2: :a, attr3: 3)
      t2 = this::TestTuple.new(attr1: 3, attr2: :a, attr3: 1)
      t3 = this::TestTuple.new(attr2: :a, attr3: 3, attr1: 1)
      t4 = this::TestTuple.new(1, :a, 3)
      t5 = this::TestTuple.new(3, :a, 1)
      [t1, t2, t3, t4, t5].each {|t| t.should.be.kind_of? this::TestTuple}
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
      t1 = this::TestTuple.new(attr1: 1, attr2: :a, attr3: true)
      t1.attr1.should == 1
      t1.attr2.should == :a
      t1.attr3.should == true
      t2 = this::TestTuple.new(attr1: 2, attr3: false)
      t2.attr1.should == 2
      t2.attr2.should.be.nil
      t2.attr3.should == false
    end

    it "should set new data in each field" do
      t = this::TestTuple.new(attr1: 1, attr2: :a, attr3: true)
      t.attr1 = 2
      t.attr2 = :b
      t.attr3 = false
      t.attr1.should.equal 2
      t.attr2.should.equal :b
      t.attr3.should.equal false
    end

    it "should get any form" do
      any = this::TestTuple.any
      any.should == this::TestTuple.new
      any.attr1.should.be.nil
      any.attr2.should.be.nil
      any.attr3.should.be.nil
    end

    it "should get tuple object from array" do
      t = TupleSpace.from_array([:test, 1, :a, true])
      t.should.be.kind_of this::TestTuple
      t.attr1.should.== 1
      t.attr2.should.== :a
      t.attr3.should.== true
      t.should.== this::TestTuple.new(attr1: 1, attr2: :a, attr3: true)
    end

    it "should raise exception when tuple is redefined by different format" do
      # different format
      should.raise(ScriptError) do
        class this::TestTuple
          define_format([:test, :attr3, :attr2, :attr1])
        end
      end
    end
  end
end
