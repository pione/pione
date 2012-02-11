require 'innocent-white/util'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'

include InnocentWhite

describe "Tuple" do
  describe "common" do
    before do
      Tuple.define_format([:test, :attr1, :attr2, :attr3])
    end

    it "should define tuple format" do
      Tuple[:test].should.not.be.nil
      Tuple[:test].ancestors.should.include Tuple::TupleData
    end

    it "should read each data" do
      t = Tuple[:test].new(attr1: 1, attr2: :a, attr3: true)
      t.attr1.should.== 1
      t.attr2.should.== :a
      t.attr3.should.== true
    end

    it "should set each data" do
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
      any.should.eql Tuple[:test].new
      any.attr1.should.be.nil
      any.attr2.should.be.nil
      any.attr3.should.be.nil
    end

    it "should get tuple from array" do
      t = [:test, 1, :a, true].to_tuple
      t.should.be.kind_of Tuple::TupleData
      t.attr1.should.== 1
      t.attr2.should.== :a
      t.attr3.should.== true
      t.should.== Tuple[:test].new(attr1: 1, attr2: :a, attr3: true)
    end
  end


  describe ":data" do
    before do
      @time = Time.now
      @t = Tuple[:data].new(name: "a.txt",
                            path: "/path/to",
                            time: @time)
    end

    it "should read name" do
      @t.name.should.equal "a.txt"
    end

    it "should read path" do
      @t.path.should.equal "/path/to"
    end

    it "should read time" do
      @t.time.should.equal @time
    end
  end
end
