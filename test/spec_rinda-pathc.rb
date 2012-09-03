require_relative 'test-util'

describe 'RindaPatch' do
  it 'should have single tuple' do
    ts = Rinda::TupleSpace.new
    e1 = ts.write([:abc, 1])
    e2 = ts.write([:abc, 1])
    e1.should == e2
    e2.should == e1
    ts.read_all([:abc, nil]).should == [[:abc, 1]]
    ts.read([:abc, 1]).should == [:abc, 1]
  end

  it 'should have two tuple' do
    ts = Rinda::TupleSpace.new
    e1 = ts.write([:abc, 1])
    e2 = ts.write([:abc, 2])
    e1.should.not == e2
    e2.should.not == e1
    ts.read_all([:abc, nil]).should == [[:abc, 1], [:abc, 2]]
    ts.read([:abc, 1]).should == [:abc, 1]
    ts.read([:abc, 2]).should == [:abc, 2]
  end
end
