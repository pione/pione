require 'drb/drb'
require 'stringio'
require 'innocent-white/agent/logger'

include InnocentWhite
Thread.abort_on_exception = true
DRb.start_service

describe "Logger" do
  before do
    @remote_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3))
    @ts_server = DRbObject.new(nil, @remote_server.uri)
    @buf = StringIO.new("", "w+")
    @logger = Agent::Logger.new(@ts_server, @buf)
    @msg1 = "e07860f6-18f0-4c1a-8a5a-7d9f3353c83f"
    @msg2 = "c8fa705d-fc30-42fa-a05f-a2493717dc39"
  end

  it "should say hello and bye" do
    @logger.wait_till(:logging)
    agents = @ts_server.read_all(Tuple[:agent].any)
    agents.should.include @logger.to_agent_tuple
    @logger.terminate
    @logger.wait_till(:terminated)
    agents = @ts_server.read_all(Tuple[:agent].any)
    agents.should.not.include @logger.to_agent_tuple
  end

  it "should log messages" do
    @ts_server.write(Tuple[:log].new(:debug, @msg1))
    @ts_server.write(Tuple[:log].new(:info, @msg2))
    @logger.wait_till(:logging)
    @logger.wait_to_clear_logs
    @buf.string.split("\n").should.include "debug: #{@msg1}"
    @buf.string.split("\n").should.include "info: #{@msg2}"
  end

  it "should terminate logging by terminate message" do
    @logger.wait_till(:logging)
    @logger.wait_to_clear_logs
    @logger.terminate
    @logger.wait_till(:terminated)
    @ts_server.write(Tuple[:log].new(:debug, @msg1))
    sleep 0.1
    @buf.string.split("\n").should.not.include "debug: #{@msg1}"
  end

  it "should terminate logging by exception" do
    @ts_server.write(Tuple[:log].new(:warn, @msg1))
    @logger.wait_to_clear_logs
    @remote_server.stop_service
    @logger.wait_till(:terminated)
    Util.ignore_exception do
      @ts_server.write(Tuple[:log].new(:warn, @msg2))
    end
    @logger.should.be.terminated
    @buf.string.split("\n").should.include "warn: #{@msg1}"
    @buf.string.split("\n").should.not.include "warn: #{@msg2}"
  end
end

