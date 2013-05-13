require_relative '../test-util'

describe 'Model::TicketExpr' do
  it 'should equal between same name ticket expressions' do
    TicketExpr.new("T").should == TicketExpr.new("T")
  end

  it 'should not equal' do
    TicketExpr.new("T").should.not == TicketExpr.new("t")
  end

  it 'should get names' do
    TicketExpr.new("T").name.should == "T"
  end

  test_pione_method("ticket-expr")
end
