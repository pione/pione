require 'innocent-white/test-util'

describe 'FeatureSet' do
  it 'should convert into an array' do
    set = FeatureSet.new('X', 'Linux', 'Interactive')
    set.to_a.should == ['X', 'Linux', 'Interactive']
  end

  it 'should convert into a set' do
    set = FeatureSet.new('X', 'Linux', 'Interactive')
    set.to_set.should == Set.new(['X', 'Linux', 'Interactive'])
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
