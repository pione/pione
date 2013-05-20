require_relative '../test-util'

describe 'Model::PackageExpr' do
  before do
    @package_expr = Model::PackageExpr.new('A')
  end

  it 'should equal' do
    @package_expr.should == Model::PackageExpr.new('A')
  end

  it 'should not equal' do
    @package_expr.should != Model::PackageExpr.new('B')
  end

  it 'should get a package name' do
    @package_expr.name.should == 'A'
  end
end
