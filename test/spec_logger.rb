require 'stringio'
require 'innocent-white/agent/logger'

include InnocentWhite
Thread.abort_on_exception = true

describe "Logger" do
  before do
    @ts_server = TupleSpaceServer.new(task_worker_resource: 3)
    @buf = StringIO.new("", "w+")
    @logger = Agent::Logger.new(@ts_server, @buf)
  end

  it "should log" do
    msg = Tuple[:log].new(level: :info, message: "hello")
    @ts_server.write(msg)
    sleep 0.1
    @buf.string.should == "info: hello\n"
  end

end

