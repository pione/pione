require_relative '../test-util'

describe 'Model::DataExpr' do
  it 'should get expression informations' do
    exp = DataExpr.new('test.a').to_seq
    exp.should.be.each
    exp.should.be.not.all
    exp.should.be.not.stdout
    exp.should.be.not.stderr
  end

  it 'should be each modifier' do
    exp = DataExpr.new('test.a').to_seq.set_each
    exp.should.be.each
    exp.should.be.not.all
    exp.should.be.file
  end

  it 'should be all modifier' do
    exp = DataExpr.new('test.a').to_seq.set_all
    exp.should.be.not.each
    exp.should.be.all
    exp.should.be.file
  end

  it 'should be stdout mode' do
    exp = DataExpr.new('test.a').to_seq.set_stdout
    exp.should.be.stdout
    exp.should.be.not.stderr
  end

  it 'should be stderr mode' do
    exp = DataExpr.new('test.a').to_seq.set_stderr
    exp.should.be.not.stdout
    exp.should.be.stderr
  end

  it 'should neglect update criteria' do
    exp = DataExpr.new('test.a').to_seq.set_neglect
    exp.should.neglect
    exp.should.not.care
  end

  it 'should care update criteria' do
    exp = DataExpr.new('test.a').to_seq.set_care
    exp.should.not.neglect
    exp.should.care
  end

  it 'should have write operation' do
    expr = DataExpr.new('A').to_seq.set_write
    expr.should.write
    expr.should.not.remove
    expr.should.not.touch
    expr.operation.should == :write
  end

  it 'should have remove operation' do
    expr = DataExpr.new('A').to_seq.set_remove
    expr.should.not.write
    expr.should.remove
    expr.should.not.touch
    expr.operation.should == :remove
  end

  it 'should have touch operation' do
    expr = DataExpr.new('A').to_seq.set_touch
    expr.should.not.write
    expr.should.not.remove
    expr.should.touch
    expr.operation.should == :touch
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
    exp.should.not.match 'test-.a'
    { 'test-1.a'=> '1',
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
    exp.should.not.match 'test--.a'
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

  it 'should handle OR relation' do
    expr = DataExpr.new('a') | DataExpr.new('b')
    expr.should.match 'a'
    expr.should.match 'b'
    expr.should.not.match 'c'
  end

  it 'should expand variables' do
    vtable1 = VariableTable.new(Variable.new('VAR') => PioneString.new('1').to_seq)
    exp1 = DataExpr.new('{$VAR}.a').eval(vtable1)
    exp1.match('1.a')
    exp1.should.not.match '1.b'
    vtable2 = VariableTable.new(Variable.new('VAR') => PioneString.new('*').to_seq)
    exp2 = DataExpr.new('{$VAR}.a').eval(vtable2)
    exp2.should.match '1.a'
    exp2.should.match '2.a'
    exp2.should.match 'abc.a'
    exp2.should.not.match '1.b'
  end

  it 'should expand an expression' do
    vtable = VariableTable.new
    vtable.set(Variable.new("X"), PioneInteger.new(1).to_seq)
    DataExpr.new('<? $X + 1 ?>.a').eval(vtable).name.should == "2.a"
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

  describe 'pione method except' do
    it 'should set a exception' do
      DataExpr.new('test.a').to_seq.call_pione_method("except", DataExpr.new('test.b').to_seq).should ==
        DataExpr.new('test.a').except(DataExpr.new('test.b')).to_seq
    end
  end
end

describe "Model::DataExprNull" do
  before do
    @null = Model::DataExprNull.instance
  end

  it "should not initialize" do
    should.raise(NoMethodError) do
      Model::DataExprNull.new
    end
  end

  it "should not match any data" do
    @null.should.not.match('test.a')
  end

  it "should return itselt" do
    @null.all.should == @null
    @null.each.should == @null
    @null.stdout.should == @null
    @null.stderr.should == @null
    @null.neglect.should == @null
    @null.care.should == @null
    @null.write.should == @null
    @null.remove.should == @null
    @null.touch.should == @null
  end
end

describe "Model::DataExprOr" do
  before do
    @a = Model::DataExpr.new('A')
    @a_aster = Model::DataExpr.new('A*')
    @aa_each = Model::DataExpr.new('AA')
    @b = Model::DataExpr.new('B')
    @null = Model::DataExprNull.instance
  end

  it "should match" do
    expr = Model::DataExprOr.new([@a, @b])
    expr.should.match('A')
    expr.should.match('B')
    expr.should.not.match('C')
  end

  it "should get/set exceptions" do
    Model::DataExprOr.new([@a_aster, @b]).except(@aa_each).tap do |expr|
      expr.exceptions.should == [@aa_each]
      expr.should.match("AAA")
      expr.should.match("B")
      expr.should.not.match("AA")
      expr.should.not.match("A")
      expr.should.match("AB")
    end
  end
end

#
# test cases
#
yamlname = 'spec_data-expr_match.yml'
ymlpath = File.join(File.dirname(__FILE__), yamlname)
testcases = YAML.load_file(ymlpath)

describe "Model::DataExpr variation tests" do
  testcases.each do |expr, testcase|
    data_expr = DocumentTransformer.new.apply(
      DocumentParser.new.expr.parse(expr)
    )

    testcase['match'].map do |name|
      it "#{expr} should match #{name}" do
        data_expr.eval(VariableTable.new).first.should.match(name)
      end
    end

    testcase['unmatch'].map do |name|
      it "#{expr} should unmatch #{name}" do
        data_expr.eval(VariableTable.new).first.should.not.match(name)
      end
    end
  end

  test_pione_method("data-expr")
end
