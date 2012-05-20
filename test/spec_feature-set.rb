require 'innocent-white/test-util'

describe 'FeatureSet' do
  it 'should create a set with no elements' do
    FeatureSet.new.size.should == 0
    FeatureSet.new([]).size.should == 0
  end

  it 'should create a set with elements' do
    FeatureSet.new('A', 'B', 'C').size.should == 3
    FeatureSet.new(['A', 'B', 'C']).size.should == 3
  end

  it 'should be equal' do
    FeatureSet.new.should == FeatureSet.new
    FeatureSet.new.should == FeatureSet.new([])
    FeatureSet.new('A').should == FeatureSet.new('A')
    FeatureSet.new('A').should == FeatureSet.new(['A'])
  end

  it 'should not be equal' do
    FeatureSet.new('A').should.not == FeatureSet.new
    FeatureSet.new.should.not == FeatureSet.new('A')
    FeatureSet.new('A').should.not == FeatureSet.new('B')
    FeatureSet.new('A').should.not == FeatureSet.new('A', 'B')
    FeatureSet.new('A', 'B').should.not == FeatureSet.new('A')
  end

  it 'should convert into an array' do
    set = FeatureSet.new('X', 'Linux', 'Interactive')
    set.to_a.should == ['X', 'Linux', 'Interactive']
  end

  it 'should convert into a set' do
    set = FeatureSet.new('X', 'Linux', 'Interactive')
    set.to_set.should == Set.new(['X', 'Linux', 'Interactive'])
  end

  it 'should be empty' do
    FeatureSet.new.should.empty
  end

  it 'should not be empty' do
    FeatureSet.new('A').should.not.be.empty
  end

  it 'should be true when comparing by #===' do
    set = FeatureSet.new('X', 'Linux', 'Interactive')
    set.should === []
    set.should === ['X']
    set.should === ['Linux']
    set.should === ['Interactive']
    set.should === ['X', 'Linux']
    set.should === ['X', 'Interactive']
    set.should === ['Linux', 'Interactive']
    set.should === ['X', 'Linux', 'Interactive']
  end

  it 'should be false when comparing by #===' do
    set = FeatureSet.new('X', 'Linux', 'Interactive')
    set.should.not === ['Y']
    set.should.not === ['X', 'Y']
  end
end
