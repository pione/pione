require_relative '../test-util'

describe 'Model::Ticket' do
  before do
    @ticket = Ticket.new("T")
  end

  it 'should equal' do
    @ticket.should == Ticket.new("T")
  end

  it 'should not equal' do
    @ticket.should.not == Ticket.new("t")
  end

  it 'shoud get name' do
    @ticket.name.should == "T"
  end

  describe 'pione method ==' do
    it 'should true' do
      @ticket.call_pione_method("==", Ticket.new("T")).should.true
    end

    it 'should false' do
      @ticket.call_pione_method("==", Ticket.new("t")).should.not.true
    end

    it 'should raise type error' do
      should.raise(PioneModelTypeError) do
        @ticket.call_pione_method("==", PioneString.new("T"))
      end
    end
  end
end
