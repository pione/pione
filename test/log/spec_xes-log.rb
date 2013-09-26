require 'pione/test-helper'

raw_process_log = Pione::Location[File.join(File.dirname(__FILE__), "raw-process-log", "pione-process.log")]

describe 'Pione::XESLog' do
  it 'should format XES log' do
    Log::XESLog.read(raw_process_log).values.each do |log|
      result = log.format
      result.should.kind_of String
      result.size.should > 0
    end
  end
end
