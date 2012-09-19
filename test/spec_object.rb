require_relative 'test-util'

describe 'PioneObject' do
  it "should get UUID as string" do
    PioneObject.new.uuid.size.should == 36
  end

  it "should get same UUID from same object" do
    obj1 = PioneObject.new
    obj1.uuid.should == obj1.uuid
  end

  it "should get different uuids from different objects" do
    obj1 = PioneObject.new
    obj2 = PioneObject.new
    obj1.uuid.should == obj1.uuid
    obj1.uuid.should.not == obj2.uuid
  end
end

