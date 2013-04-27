require_relative '../test-util'

describe 'Model::RuleExpr' do
  before do
    @a = RuleExpr.new(Package.new("main"), "a")
    @b = RuleExpr.new(Package.new("main"), "b")
  end

  it 'should be equal' do
    @a.should == RuleExpr.new(Package.new("main"), "a")
  end

  it 'should be not equal' do
    @a.should.not == @b
  end

  it 'should set/get input ticket expression' do
    ticket = TicketExpr.new(["A"])
    @a.add_input_ticket_expr(ticket).input_ticket_expr.should == ticket
  end

  it 'should set/get output ticket expression' do
    ticket = TicketExpr.new(["A"])
    @a.add_output_ticket_expr(ticket).output_ticket_expr.should == ticket
  end

  describe 'pione method ==' do
    it 'should true' do
      @a.call_pione_method(
        "==", RuleExpr.new(Package.new("main"), "a")
      ).should.true
    end

    it 'should false' do
      @a.call_pione_method("==", @b).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @a.call_pione_method("==", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method !=' do
    it 'should true' do
      @a.call_pione_method("!=", @b).should.true
    end

    it 'should false' do
      @a.call_pione_method(
        "!=", RuleExpr.new(Package.new("main"), "a")
      ).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @a.call_pione_method("!=", PioneInteger.new(1))
      end
    end
  end

  describe 'pione method as_string' do
    it 'should get string' do
      @a.call_pione_method("as_string").should == PioneString.new("a")
    end
  end

  describe 'pione method params' do
    it 'should set parameters' do
      params = Parameters.new({Variable.new("a") => PioneBoolean.true})
      @a.call_pione_method("params", params).should ==
        RuleExpr.new(Package.new("main"), "a", params: params)
    end
  end
end
