require_relative '../test-util'

describe 'Model::RuleExpr' do
  before do
    @a = RuleExpr.new(PackageExpr.new("main"), "a")
    @b = RuleExpr.new(PackageExpr.new("main"), "b")
  end

  it 'should be equal' do
    @a.should == RuleExpr.new(PackageExpr.new("main"), "a")
  end

  it 'should be not equal' do
    @a.should.not == @b
  end

  it 'should set/get input ticket expression' do
    ticket = TicketExpr.new("A").to_seq
    @a.add_input_ticket_expr(ticket).input_ticket_expr.should == ticket
  end

  it 'should set/get output ticket expression' do
    ticket = TicketExpr.new("A").to_seq
    @a.add_output_ticket_expr(ticket).output_ticket_expr.should == ticket
  end

  test_pione_method("rule-expr")
end
