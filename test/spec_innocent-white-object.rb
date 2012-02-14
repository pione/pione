require 'innocent-white/innocent-white-object'

include InnocentWhite

describe "InnocentWhiteObject" do
  it "should get uuid" do
    obj = InnocentWhiteObject.new
    obj.uuid.should == obj.uuid
  end
end
