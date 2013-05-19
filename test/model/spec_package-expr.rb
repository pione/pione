require_relative '../test-util'

describe 'Model::PackageExpr' do
  it 'should be equal' do
    Model::PackageExpr.new('abc').should == Model::PackageExpr.new('abc')
  end

  it 'should not be equal' do
    Model::PackageExpr.new('abc').should.not == Model::PackageExpr.new('def')
  end

  it 'should get a package name' do
    Model::PackageExpr.new('abc').name.should == 'abc'
  end
end
