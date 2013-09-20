require_relative '../test-util'

describe 'Lang::TicketExpr' do
  it 'should equal' do
    Lang::TicketExpr.new("T").should == Lang::TicketExpr.new("T")
  end

  it 'should not equal' do
    Lang::TicketExpr.new("T").should.not == Lang::TicketExpr.new("t")
  end

  it 'should get name' do
    Lang::TicketExpr.new("T").name.should == "T"
  end
end

describe "Pione::Lang::TicketExprSequence" do
  before do
    @x = Lang::TicketExpr.new("X")
    @y = Lang::TicketExpr.new("Y")
    @seq = Lang::TicketExprSequence.new([@x, @y])
  end

  it "should equal" do
    @seq.should == Lang::TicketExprSequence.new([@x, @y])
  end

  it "should not equal" do
    @seq.should != Lang::TicketExprSequence.new([@y, @x])
  end

  it "should get ticket names" do
    @seq.names.should.include("X")
    @seq.names.should.include("Y")
    @seq.names.should.not.include("Z")
  end

  test_pione_method "ticket-expr"
end
