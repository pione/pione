require_relative '../test-util'

location = Pione::Location[File.join(File.dirname(__FILE__), "data", "sample.log")]

describe 'Pione::XESLog' do
  it 'should format XES log' do
    result = Log::XESLog.read(location).format
    result.should.kind_of String
    result.size.should > 0
  end
end
