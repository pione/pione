require 'pione/test-helper'

describe 'Pione::Lang::RuleExpr' do
  before do
    @a = Lang::RuleExpr.new(Lang::PackageExpr.new("main"), "a")
    @b = Lang::RuleExpr.new(Lang::PackageExpr.new("main"), "b")
  end

  it 'should be equal' do
    @a.should == Lang::RuleExpr.new(Lang::PackageExpr.new("main"), "a")
  end

  it 'should be not equal' do
    @a.should.not == @b
  end

  TestHelper::Lang.test_pione_method(__FILE__)
end
