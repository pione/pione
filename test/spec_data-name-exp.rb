require 'innocent-white/test-util'
require 'innocent-white/data-name-exp'

setup_test

describe 'DataNameExp' do
  it 'should get each modifier' do
    exp = DataNameExp['test-*.a']
    exp.modifier.should == :each
    exp.all?.should.be.false
    exp.each?.should.be.true
  end

  it 'should get all modifier' do
    exp = DataNameExp.all('test-*.a')
    exp.modifier.should == :all
    exp.all?.should.be.true
    exp.each?.should.be.false
  end

  it 'should match the same name' do
    exp = DataNameExp['test-1.a']
    exp.should.match 'test-1.a'
    exp.should.not.match 'test-1_a'
  end

  it 'should not be regular expression' do
    exp = DataNameExp['test-\d.a']
    exp.should.not.match 'test-1.a'
  end

  it 'should handle wildcard "*" as /(.*)/ (Case 1)' do
    exp = DataNameExp['test-*.a']
    exp.should.match 'test-.a'
    exp.match('test-.a')[1].should == ''
    exp.should.match 'test-1.a'
    exp.match('test-1.a')[1].should == '1'
    exp.should.match 'test-2.a'
    exp.match('test-2.a')[1].should == '2'
    exp.should.match 'test-3.a'
    exp.match('test-3.a')[1].should == '3'
    exp.should.match 'test-A.a'
    exp.match('test-A.a')[1].should == 'A'
    exp.should.match 'test-abc.a'
    exp.match('test-abc.a')[1].should == 'abc'
    exp.should.not.match 'test-1_a'
    exp.should.not.match '-1.a'
    exp.should.not.match 'test-1.ab'
    exp.should.not.match 'ttest-1.a'
  end

  it 'should handle wildcard "*" as /(.*)/ (Case 2)'do
    exp = DataNameExp['test-*-*.a']
    exp.should.match 'test-1-2.a'
    exp.match('test-1-2.a')[1].should == '1'
    exp.match('test-1-2.a')[2].should == '2'
    exp.should.match 'test-abc-xyz.a'
    exp.match('test-abc-xyz.a')[1].should == 'abc'
    exp.match('test-abc-xyz.a')[2].should == 'xyz'
    exp.should.match 'test--.a'
    exp.match('test--.a')[1].should == ''
    exp.match('test--.a')[2].should == ''
    exp.should.not.match('test-1.a')
    exp.should.not.match('test-1-2.b')
    exp.should.not.match('test-1-2')
    exp.should.not.match('-1-2.a')
    exp.should.not.match 'test-1-2.ab'
    exp.should.not.match 'ttest-1-2.a'
  end

  it 'should handle "?" as /(.)/ (Case 1)' do
    exp = DataNameExp['test-?.a']
    exp.should.match 'test-1.a'
    exp.match('test-1.a')[1].should == '1'
    exp.should.match 'test-2.a'
    exp.match('test-2.a')[1].should == '2'
    exp.should.match 'test-3.a'
    exp.match('test-3.a')[1].should == '3'
    exp.should.match 'test-A.a'
    exp.match('test-A.a')[1].should == 'A'
    exp.should.not.match 'test-abc.a'
    exp.should.not.match 'test-.a'
    exp.should.not.match 'test-1_a'
    exp.should.not.match 'test-1.ab'
    exp.should.not.match 'ttest-1.a'
  end

  it 'should handle "?" as /(.)/ (Case 2)' do
    exp = DataNameExp['test-?-?.a']
    exp.should.match 'test-1-2.a'
    exp.match('test-1-2.a')[1].should == '1'
    exp.match('test-1-2.a')[2].should == '2'
    exp.should.not.match 'test--.a'
    exp.should.not.match 'test-abc-a.a'
    exp.should.not.match 'test-a-abc.a'
    exp.should.not.match 'test-1-2.ab'
    exp.should.not.match 'ttest-1-2.a'
  end

  it 'should handle exceptions (Case 1)' do
    exp = DataNameExp['test-*.a'].except('test-2.a')
    exp.should.match 'test-1.a'
    exp.should.not.match 'test-2.a'
    exp.should.match 'test-22.a'
  end

  it 'should handle exceptions (Case 2)' do
    exp = DataNameExp['*'].except('test-1.a','test-2.a')
    exp.should.not.match 'test-1.a'
    exp.should.not.match 'test-2.a'
    exp.should.match 'test-3.a'
  end

  it 'should handle exceptions (Case 3)' do
    exp = DataNameExp['test-1.a'].except('*')
    exp.should.not.match 'test-1.a'
  end

  it 'should expand variables' do
    exp1 = DataNameExp['{$VAR}.a'].with_variables('VAR' => '1')
    exp1.match('1.a')
    exp1.should.not.match '1.b'
    exp2 = DataNameExp['{$VAR}.a'].with_variables('VAR' => '*')
    exp2.should.match '1.a'
    exp2.should.match '2.a'
    exp2.should.match 'abc.a'
    exp2.should.not.match '1.b'
  end

  it 'should generate a name (Case 1)' do
    exp = DataNameExp['test-*.a']
    exp.generate(1).should == 'test-1.a'
    exp.generate(123).should == 'test-123.a'
    exp.generate(1,2,3).should == 'test-1.a'
  end

  it 'should generate a name (Case 2)' do
    exp = DataNameExp['test-*-*.a']
    exp.generate(1,2).should == 'test-1-2.a'
    exp.generate(123, 456).should == 'test-123-456.a'
    exp.generate(1).should == 'test-1-*.a'
  end

  it 'should generate a name (Case 3)' do
    exp = DataNameExp['test-?.a']
    exp.generate(1).should == 'test-1.a'
    exp.generate(2).should == 'test-2.a'
    exp.generate(123).should == 'test-1.a'
  end

  it 'should select names matched with the expression' do
    exp = DataNameExp['test-?.a']
    exp.select('test-.a','test-1.a','test-a.a','test-a.b').should == ['test-1.a', 'test-a.a']
    exp.select.should.empty
  end
end
