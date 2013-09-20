require_relative '../test-util'

describe 'Pione::Lang::PackageExpr' do
  before do
    @package_expr = Lang::PackageExpr.new('A')
  end

  it 'should equal' do
    @package_expr.should == Lang::PackageExpr.new('A')
  end

  it 'should not equal' do
    @package_expr.should != Lang::PackageExpr.new('B')
  end

  it 'should get a package name' do
    @package_expr.name.should == 'A'
  end
end
