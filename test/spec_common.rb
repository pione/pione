require_relative 'test-util'

describe 'Common' do
  it 'should ignore exception' do
    should.not.raise(Exception) do
      ignore_exception { raise Exception }
    end
  end

  it 'should get hostname' do
    get_hostname.should == `hostname`.chomp
  end
end

