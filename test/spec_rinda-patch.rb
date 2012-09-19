require_relative 'test-util'

describe 'RindaPatch' do
  it 'should be different tuples that have different contentes' do
    ts = Rinda::TupleSpace.new
    e1 = ts.write([:abc, 1])
    e2 = ts.write([:abc, 2])
    e1.should.not == e2
    e2.should.not == e1
    ts.read_all([:abc, nil]).should == [[:abc, 1], [:abc, 2]]
    ts.read([:abc, 1]).should == [:abc, 1]
    ts.read([:abc, 2]).should == [:abc, 2]
  end

  it 'should not unify normal tuples' do
    ts = Rinda::TupleSpace.new
    e1 = ts.write([:abc, 1])
    e2 = ts.write([:abc, 1])
    e1.should == e2
    e2.should == e1
    ts.read_all([:abc, nil]).should == [[:abc, 1], [:abc, 1]]
    ts.read([:abc, 1]).should == [:abc, 1]
  end

  it 'should unify domain based tuples' do
    ts = Rinda::TupleSpace.new
    ts.write([:working, "test", "test"])
    ts.write([:working, "test", "test"])
    ts.write([:working, "test", "test"])
    ts.read_all([:working, nil, nil]).should == [[:working, "test", "test"]]
  end
end
