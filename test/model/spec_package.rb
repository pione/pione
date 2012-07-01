require_relative '../test-util'

describe 'Model::Package' do
  it 'should be equal' do
    Model::Package.new('abc').should == Model::Package.new('abc')
  end

  it 'should not be equal' do
    Model::Package.new('abc').should.not == Model::Package.new('def')
  end

  it 'should get a package name' do
    Model::Package.new('abc').name.should == 'abc'
  end
end
