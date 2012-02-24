require 'innocent-white/test-util'

describe 'Common' do
  describe "InnocentWhiteObject" do
    it "should get uuid" do
      obj1 = InnocentWhiteObject.new
      obj2 = InnocentWhiteObject.new
      obj1.uuid.should == obj1.uuid
      obj1.uuid.should.not == obj2.uuid
    end
  end

  describe 'Util' do
    it 'should ignore exception' do
      should.not.raise(Exception) do
        Util.ignore_exception { raise Exception }
      end
    end

    it 'should get hostname' do
      Util.hostname.should == `hostname`.chomp
    end

    it 'should get taskid' do
      id1 = Util.taskid([],[])
      id2 = Util.taskid(["1.a"], [])
      id3 = Util.taskid(["2.a"], [])
      id4 = Util.taskid([],["1.a"])
      id5 = Util.taskid([],["2.a"])
      id6 = Util.taskid(["1.a"], ["1.a"])
      id7 = Util.taskid(["2.a"], ["2.a"])
      7.times do |i|
        eval "id#{i+1}.size.should == 32"
        7.times do |ii|
          eval "id#{i+1}.should.not == id#{ii+1}" unless i == ii
        end
      end
      id1.should == Util.taskid([],[])
      id2.should == Util.taskid(["1.a"], [])
      id3.should == Util.taskid(["2.a"], [])
      id4.should == Util.taskid([],["1.a"])
      id5.should == Util.taskid([],["2.a"])
      id6.should == Util.taskid(["1.a"], ["1.a"])
      id7.should == Util.taskid(["2.a"], ["2.a"])
    end
  end
end

