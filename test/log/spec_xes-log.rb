require_relative '../test-util'

raw_process_log = Pione::Location[File.join(File.dirname(__FILE__), "raw-process-log", "pione-process.log")]

describe 'Pione::XESLog' do
  it 'should format XES log' do
    result = Log::XESLog.read(raw_process_log).format
    result.should.kind_of String
    result.size.should > 0
  end
end
