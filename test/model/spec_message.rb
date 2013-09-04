require_relative '../test-util'

describe 'Model::Message' do
  before do
    @a = Model::Message.new("next", IntegerSequence.of(1), [])
    @b = Model::Message.new("substring", StringSequence.of("abcdefg"), [IntegerSequence.of(2), IntegerSequence.of(3)])
  end

  it 'should equal' do
    @a.should == Model::Message.new("next", IntegerSequence.of(1), [])
    @b.should == Model::Message.new("substring", StringSequence.of("abcdefg"), [IntegerSequence.of(2), IntegerSequence.of(3)])
  end

  it 'should not equal' do
    @a.should.not == @b
  end

  it 'should send message' do
    @a.eval(Lang::Environment.new).should == Model::IntegerSequence.of(2)
    @b.eval(Lang::Environment.new).should == Model::StringSequence.of("bcd")
  end
end
