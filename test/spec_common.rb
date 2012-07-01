require_relative 'test-util'

describe 'Common' do
  describe "PioneObject" do
    it "should get uuid" do
      obj1 = PioneObject.new
      obj2 = PioneObject.new
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

    it 'should get task_id' do
      id1 = Util.task_id([],[])
      id2 = Util.task_id([DataExpr["1.a"]], [])
      id3 = Util.task_id([DataExpr["2.a"]], [])
      id4 = Util.task_id([],["1.a"])
      id5 = Util.task_id([],["2.a"])
      id6 = Util.task_id([DataExpr["1.a"]], ["1.a"])
      id7 = Util.task_id([DataExpr["2.a"]], ["2.a"])
      7.times do |i|
        eval "id#{i+1}.size.should == 32"
        7.times do |ii|
          eval "id#{i+1}.should.not == id#{ii+1}" unless i == ii
        end
      end
      id1.should == Util.task_id([],[])
      id2.should == Util.task_id([DataExpr["1.a"]], [])
      id3.should == Util.task_id([DataExpr["2.a"]], [])
      id4.should == Util.task_id([],["1.a"])
      id5.should == Util.task_id([],["2.a"])
      id6.should == Util.task_id([DataExpr["1.a"]], ["1.a"])
      id7.should == Util.task_id([DataExpr["2.a"]], ["2.a"])
    end
  end
end

