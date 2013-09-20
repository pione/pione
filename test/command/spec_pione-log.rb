require_relative '../test-util'
require_relative 'command-behavior'

describe "Pione::Command::PioneLog" do
  raw_log_location = TestUtil::DIR + "command" + "data" + "pione-process.log"

  behaves_like "command"

  it "should generate rule process log" do
    res = TestUtil::Command.succeed do
      Command::PioneLog.run ["--rule-process", "--location", raw_log_location.path.to_s]
    end
    res.stdout.string.chomp.size.should > 0
  end

  it "should generate task process log" do
    res = TestUtil::Command.succeed do
      Command::PioneLog.run ["--task-process", "--location", raw_log_location.path.to_s]
    end
    res.stdout.string.chomp.size.should > 0
  end

  it "should fail if format is unknown" do
    res = TestUtil::Command.fail do
      Command::PioneLog.run ["--format", "xxx", "--location", raw_log_location.path.to_s]
    end
  end
end
