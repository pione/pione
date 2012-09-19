require_relative '../test-util'

describe 'Model::RuleIOElement' do
  it 'should have name as a pione string' do
    RuleIOElement.new("a.txt").name.should.kind_of?(PioneString)
  end

  it 'should have uri as a pione string' do
    elt = RuleIOElement.new("a.txt")
    elt.uri = "local:./test/a.txt"
    elt.uri.should.kind_of?(PioneString)
  end
end

describe 'Model::RuleIOList' do
  it 'should add elements' do
    list = RuleIOList.new
    list.add(RuleIOElement.new("a.txt"))
      .add(RuleIOElement.new("b.txt"))
      .add(RuleIOElement.new("c.txt"))
      .elements.size.should == 3
    list.elements.size.should == 0
  end

  it 'should add elements destructively' do
    list = RuleIOList.new
    list.add! RuleIOElement.new("a.txt")
    list.add! RuleIOElement.new("b.txt")
    list.add! RuleIOElement.new("c.txt")
    list.elements.size.should == 3
  end
end
