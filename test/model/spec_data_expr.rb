require_relative '../test-util'

describe 'Model::DataExpr' do
  it 'should get expression informations' do
    exp = DataExpr.new('test.a')
    exp.should.be.each
    exp.should.be.not.all
    exp.should.be.not.stdout
    exp.should.be.not.stderr
  end

  it 'should be a name expression with each modifier' do
    exp = DataExpr.each('test.a')
    exp.should == DataExpr.new('test.a').each
    exp.should.be.each
    exp.should.be.not.all
    exp.mode.should.be.nil
  end

  it 'should be a name expression with all modifier' do
    exp = DataExpr.all('test.a')
    exp.should == DataExpr.new('test.a').all
    exp.should.be.not.each
    exp.should.be.all
    exp.mode.should.be.nil
  end

  it 'should be a name expression with stdout mode' do
    exp = DataExpr.new('test.a').stdout
    exp.should.be.stdout
    exp.should.be.not.stderr
  end

  it 'should be a name expression with stderr mode' do
    exp = DataExpr.new('test.a').stderr
    exp.should.be.not.stdout
    exp.should.be.stderr
  end

  it 'should match the same name' do
    exp = DataExpr.new('test.a')
    exp.should.match 'test.a'
    exp.should.not.match 'test_a'
  end

  it 'should not be regular expression' do
    exp = DataExpr.new('test-\d.a')
    exp.should.not.match 'test-1.a'
  end

  it 'should handle multi characters matcher (Case 1)' do
    exp = DataExpr.new('test-*.a')
    exp.should.match 'test-.a'
    { 'test-.a' => '',
      'test-1.a'=> '1',
      'test-2.a' => '2',
      'test-3.a' => '3',
      'test-A.a' => 'A',
      'test-abc.a' => 'abc'
    }.each do |name, val|
      exp.should.match name
      exp.match(name)[1].should == val
    end
    exp.should.not.match 'test-1_a'
    exp.should.not.match '-1.a'
    exp.should.not.match 'test-1.ab'
    exp.should.not.match 'ttest-1.a'
  end

  it 'should handle multi characters matcher (Case 2)'do
    exp = DataExpr.new('test-*-*.a')
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

  it 'should handle single character matcher (Case 1)' do
    exp = DataExpr.new('test-?.a')
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

  it 'should handle single character matcher (Case 2)' do
    exp = DataExpr.new('test-?-?.a')
    exp.should.match 'test-1-2.a'
    exp.match('test-1-2.a')[1].should == '1'
    exp.match('test-1-2.a')[2].should == '2'
    exp.should.not.match 'test--.a'
    exp.should.not.match 'test-abc-a.a'
    exp.should.not.match 'test-a-abc.a'
    exp.should.not.match 'test-1-2.ab'
    exp.should.not.match 'ttest-1-2.a'
  end

  it 'should handle character set matcher (Case 1)' do
    exp = DataExpr.new('test-[1-3].a')
    exp.should.not.match 'test-0.a'
    exp.should.match 'test-1.a'
    exp.should.match 'test-2.a'
    exp.should.match 'test-3.a'
    exp.should.not.match 'test-4.a'
    exp.should.not.match 'test-5.a'
    exp.should.not.match 'test-6.a'
    exp.should.not.match 'test-7.a'
    exp.should.not.match 'test-8.a'
    exp.should.not.match 'test-9.a'
    exp.should.not.match 'test-11.a'
  end

  it 'should handle character set matcher (Case 2)' do
    exp = DataExpr.new('test-[^1-3].a')
    exp.should.match 'test-0.a'
    exp.should.not.match 'test-1.a'
    exp.should.not.match 'test-2.a'
    exp.should.not.match 'test-3.a'
    exp.should.match 'test-4.a'
    exp.should.match 'test-5.a'
    exp.should.match 'test-6.a'
    exp.should.match 'test-7.a'
    exp.should.match 'test-8.a'
    exp.should.match 'test-9.a'
    exp.should.not.match 'test-11.a'
  end

  it 'should handle character set matcher (Case 3)' do
    exp = DataExpr.new('test-[!1-3].a')
    exp.should.match 'test-0.a'
    exp.should.not.match 'test-1.a'
    exp.should.not.match 'test-2.a'
    exp.should.not.match 'test-3.a'
    exp.should.match 'test-4.a'
    exp.should.match 'test-5.a'
    exp.should.match 'test-6.a'
    exp.should.match 'test-7.a'
    exp.should.match 'test-8.a'
    exp.should.match 'test-9.a'
    exp.should.not.match 'test-11.a'
  end

  it 'should handle select matcher' do
    exp = DataExpr.new('test-{abc,def,ghi}.a')
    exp.should.not.match 'test-a.a'
    exp.should.match 'test-abc.a'
    exp.should.match 'test-def.a'
    exp.should.match 'test-ghi.a'
    exp.should.not.match 'test-bcd.a'
    exp.should.not.match 'test-efg.a'
    exp.should.not.match 'test-abcd.a'
  end

  it 'should handle exceptions (Case 1)' do
    exp = DataExpr.new('test-*.a').except('test-2.a')
    exp.should.match 'test-1.a'
    exp.should.not.match 'test-2.a'
    exp.should.match 'test-22.a'
  end

  it 'should handle exceptions (Case 2)' do
    exp = DataExpr.new('*').except('test-1.a').except('test-2.a')
    exp.should.not.match 'test-1.a'
    exp.should.not.match 'test-2.a'
    exp.should.match 'test-3.a'
  end

  it 'should handle exceptions (Case 3)' do
    exp = DataExpr.new('test-1.a').except('*')
    exp.should.not.match 'test-1.a'
  end

  it 'should expand variables' do
    vtable1 = VariableTable.new(Variable.new('VAR') => PioneString.new('1'))
    exp1 = DataExpr.new('{$VAR}.a').with_variable_table(vtable1)
    exp1.match('1.a')
    exp1.should.not.match '1.b'
    vtable2 = VariableTable.new(Variable.new('VAR') => PioneString.new('*'))
    exp2 = DataExpr.new('{$VAR}.a').with_variable_table(vtable2)
    exp2.should.match '1.a'
    exp2.should.match '2.a'
    exp2.should.match 'abc.a'
    exp2.should.not.match '1.b'
  end

  it 'should generate a name (Case 1)' do
    exp = DataExpr.new('test-*.a')
    exp.generate(1).should == 'test-1.a'
    exp.generate(123).should == 'test-123.a'
    exp.generate(1,2,3).should == 'test-1.a'
  end

  it 'should generate a name (Case 2)' do
    exp = DataExpr.new('test-*-*.a')
    exp.generate(1,2).should == 'test-1-2.a'
    exp.generate(123, 456).should == 'test-123-456.a'
    exp.generate(1).should == 'test-1-*.a'
  end

  it 'should generate a name (Case 3)' do
    exp = DataExpr.new('test-?.a')
    exp.generate(1).should == 'test-1.a'
    exp.generate(2).should == 'test-2.a'
    exp.generate(123).should == 'test-1.a'
  end

  it 'should select names matched with the expression' do
    exp = DataExpr.new('test-?.a')
    exp.select('test-.a','test-1.a','test-a.a','test-a.b').should == ['test-1.a', 'test-a.a']
    exp.select.should.empty
  end
end
