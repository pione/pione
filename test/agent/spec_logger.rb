require 'drb/drb'
require 'stringio'
require 'innocent-white/test-util'
require 'innocent-white/agent/logger'

DRb.start_service

describe "Agent::Logger" do
  before do
    create_remote_tuple_space_server
    @buf = StringIO.new("", "w+")
    @logger = Agent[:logger].start(get_tuple_space_server, @buf)
    @msg1 = "e07860f6-18f0-4c1a-8a5a-7d9f3353c83f"
    @msg2 = "c8fa705d-fc30-42fa-a05f-a2493717dc39"
  end

  it "should say hello and bye" do
    # say hello
    @logger.wait_till(:logging)
    agents = read_all(Tuple[:agent].any)
    agents.should.include @logger.to_agent_tuple
    # say bye
    @logger.terminate
    @logger.wait_till(:terminated)
    agents = read_all(Tuple[:agent].any)
    agents.should.not.include @logger.to_agent_tuple
  end

  it "should log messages" do
    # send log messages
    write(Tuple[:log].new(:debug, @msg1))
    write(Tuple[:log].new(:info, @msg2))
    @logger.wait_till(:logging)
    @logger.wait_to_clear_logs
    # check messages
    @buf.string.split("\n").should.include "debug: #{@msg1}"
    @buf.string.split("\n").should.include "info: #{@msg2}"
  end

  it "should terminate logging by terminate message" do
    # terminate
    @logger.wait_till(:logging)
    @logger.wait_to_clear_logs
    @logger.terminate
    @logger.wait_till(:terminated)
    # write a message after logger was terminated
    write(Tuple[:log].new(:debug, @msg1))
    sleep 0.1 # wait a little...
    @buf.string.split("\n").should.not.include "debug: #{@msg1}"
  end

  it "should terminate logging by exception" do
    # write a message
    write(Tuple[:log].new(:warn, @msg1))
    @logger.wait_to_clear_logs
    # remote server is shoutdown
    remote_drb_server.stop_service
    @logger.wait_till(:terminated)
    # write a message after remote server was down
    Util.ignore_exception do
      write(Tuple[:log].new(:warn, @msg2))
    end
    # logger is terminated
    @logger.should.be.terminated
    # check log content
    @buf.string.split("\n").should.include "warn: #{@msg1}"
    @buf.string.split("\n").should.not.include "warn: #{@msg2}"
  end
end
