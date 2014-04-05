require 'pione/test-helper'

describe Pione::Util::BooleanValue do
  it "should convert to true" do
    Util::BooleanValue.of(true).should.true
    Util::BooleanValue.of("true").should.true
    Util::BooleanValue.of("TRUE").should.true
    Util::BooleanValue.of("t").should.true
    Util::BooleanValue.of("T").should.true
    Util::BooleanValue.of("yes").should.true
    Util::BooleanValue.of("YES").should.true
    Util::BooleanValue.of("y").should.true
    Util::BooleanValue.of("Y").should.true
    Util::BooleanValue.of(1).should.true
    Util::BooleanValue.of(1.0).should.true
  end

  it "should convert to true" do
    Util::BooleanValue.of(false).should.false
    Util::BooleanValue.of("false").should.false
    Util::BooleanValue.of("FALSE").should.false
    Util::BooleanValue.of("f").should.false
    Util::BooleanValue.of("F").should.false
    Util::BooleanValue.of("no").should.false
    Util::BooleanValue.of("NO").should.false
    Util::BooleanValue.of("n").should.false
    Util::BooleanValue.of("N").should.false
    Util::BooleanValue.of(-1).should.false
    Util::BooleanValue.of(-1.0).should.false
    Util::BooleanValue.of(0).should.false
  end
end
