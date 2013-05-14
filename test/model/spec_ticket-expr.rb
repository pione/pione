require_relative '../test-util'

describe 'Model::TicketExpr' do
  it 'should equal' do
    TicketExpr.new("T").should == TicketExpr.new("T")
  end

  it 'should not equal' do
    TicketExpr.new("T").should.not == TicketExpr.new("t")
  end

  it 'should get name' do
    TicketExpr.new("T").name.should == "T"
  end
end

describe "Pione::Model::TicketExprSequence" do
  before do
    @x = TicketExpr.new("X")
    @y = TicketExpr.new("Y")
    @seq = TicketExprSequence.new([@x, @y])
  end

  it "should equal" do
    @seq.should == TicketExprSequence.new([@x, @y])
  end

  it "should not equal" do
    @seq.should != TicketExprSequence.new([@y, @x])
  end

  it "should get ticket names" do
    @seq.names.should.include("X")
    @seq.names.should.include("Y")
    @seq.names.should.not.include("Z")
  end

  test_pione_method "ticket-expr"
end
