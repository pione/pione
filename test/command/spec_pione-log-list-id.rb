require 'pione/test-helper'
require_relative 'command-behavior'

describe Pione::Command::PioneLogFormat do
  raw_log_location = Location[File.dirname(__FILE__)] + "data" + "pione-process.log"

  before do
    @cmd = Pione::Command::PioneLogFormat
  end

  behaves_like "command"

  it "should get log IDs" do
    res = Rootage::ScenarioTest.succeed(@cmd.new([raw_log_location.path.to_s]))
    res.stdout.string.chomp.size.should > 0
  end
end
