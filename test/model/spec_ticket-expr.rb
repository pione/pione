require_relative '../test-util'

describe 'Model::TicketExpr' do
  it 'should get empty ticket expression' do
    TicketExpr.empty.should.empty
  end

  it 'should equal between same name ticket expressions' do
    TicketExpr.new(["T"]).should == TicketExpr.new(["T"])
  end

  it 'should not equal' do
    TicketExpr.new(["T"]).should.not == TicketExpr.new(["t"])
  end

  it 'should get names' do
    TicketExpr.new(["T"]).names.should == Set.new(["T"])
  end

  it 'should make complex ticket' do
    (TicketExpr.new(["T1"]) + TicketExpr.new(["T2"])).should == TicketExpr.new(["T1", "T2"])
  end

  describe 'pione method: ==' do
    it 'should true' do
      TicketExpr.new(["T"]).call_pione_method("==", TicketExpr.new(["T"])).should.true
    end

    it 'should false' do
      TicketExpr.new(["T"]).call_pione_method("==", TicketExpr.new(["t"])).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        TicketExpr.new(["T"]).call_pione_method("==", PioneString.new("T"))
      end
    end
  end

  describe 'pione method: !=' do
    it 'should true' do
      TicketExpr.new(["T"]).call_pione_method("!=", TicketExpr.new(["t"])).should.true
    end

    it 'should false' do
      TicketExpr.new(["T"]).call_pione_method("!=", TicketExpr.new(["T"])).should.false
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        TicketExpr.new(["T"]).call_pione_method("==", PioneString.new("T"))
      end
    end
  end

  describe 'pione method: +' do
    it 'should make complex ticket expression' do
      TicketExpr.new(["T1"]).call_pione_method("+", TicketExpr.new(["T2"]))
        .should == TicketExpr.new(["T1", "T2"])
    end

    it 'should get itself' do
      TicketExpr.new(["T"]).call_pione_method("+", TicketExpr.new(["T"]))
        .should == TicketExpr.new(["T"])
    end
  end
end
