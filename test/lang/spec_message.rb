require_relative '../test-util'

describe 'Pione::Lang::Message' do
  before do
    @a = Lang::Message.new("next", Lang::IntegerSequence.of(1), [])
    @b = Lang::Message.new("substring", Lang::StringSequence.of("abcdefg"), [Lang::IntegerSequence.of(2), Lang::IntegerSequence.of(3)])
  end

  it 'should equal' do
    @a.should == Lang::Message.new("next", Lang::IntegerSequence.of(1), [])
    @b.should == Lang::Message.new("substring", Lang::StringSequence.of("abcdefg"), [Lang::IntegerSequence.of(2), Lang::IntegerSequence.of(3)])
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    @a.eval(Lang::Environment.new).should == Lang::IntegerSequence.of(2)
    @b.eval(Lang::Environment.new).should == Lang::StringSequence.of("bcd")
  end
end
