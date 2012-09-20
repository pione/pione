require_relative '../test-util'

describe 'Model::List' do
  it 'should be equal' do
    x1 = PioneList.new
    x2 = PioneList.new
    x1.should.be.equal x2
  end

  it 'should be equal with elements' do
    x1 = PioneList.new(PioneString.new("abc"), PioneString.new("def"))
    x2 = PioneList.new(PioneString.new("abc"), PioneString.new("def"))
    x1.should.be.equal x2
  end

  it 'should not be equal' do
    x1 = PioneList.new(PioneString.new("abc"))
    x2 = PioneList.new(PioneString.new("abc"), PioneString.new("def"))
    x1.should.not.be.equal x2
  end

  it 'should have type [string]' do
    list = PioneList.new(PioneString.new("abc"))
    list.pione_model_type.should == TypeList.new(TypeString)
  end
end
