require 'drb/drb'
require 'stringio'
require_relative '../test-util'
require 'pione/agent/logger'

DRb.start_service

describe "Agent::Logger" do
  before do
    create_remote_tuple_space_server
    @buf = StringIO.new("", "w+")
    @logger = Agent[:logger].start(tuple_space_server, @buf)
    @msg1 = "e07860f6-18f0-4c1a-8a5a-7d9f3353c83f"
    @msg2 = "c8fa705d-fc30-42fa-a05f-a2493717dc39"
  end

  after do
    tuple_space_server.terminate
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
    write(Tuple[:log].new(Log.new{|msg| msg.add_record(:test, :key, @msg1)}))
    write(Tuple[:log].new(Log.new{|msg| msg.add_record(:test, :key, @msg2)}))
    @logger.wait_till(:logging)
    @logger.wait_to_clear_logs
    # check messages
    @buf.string.should.include @msg1
    @buf.string.should.include @msg2
  end

  it "should terminate logging by terminate message" do
    # terminate
    @logger.wait_till(:logging)
    @logger.wait_to_clear_logs
    @logger.terminate
    @logger.wait_till(:terminated)
    # write a message after logger was terminated
    write(Tuple[:log].new(Log.new{|msg| msg.add_record(:test, :key, @msg1)}))
    sleep 0.1 # wait a little...
    @buf.string.should.not.include @msg1
  end

  it "should terminate logging by exception" do
    # write a message
    write(Tuple[:log].new(Log.new{|msg| msg.add_record(:test, :key, @msg1)}))
    @logger.wait_to_clear_logs
    # remote server is shoutdown
    remote_drb_server.stop_service
    DRb.stop_service
    DRb.remove_server(remote_drb_server)
    p remote_drb_server
    p tuple_space_server

    tuple_space_server.write(Tuple[:data].new)
    @logger.wait_till(:terminated)
    # write a message after remote server was down
    Util.ignore_exception do
      write(Tuple[:log].new(Log.new{|msg| msg.add_record(:test, :key, @msg2)}))
    end
    # logger is terminated
    @logger.should.be.terminated
    # check log content
    @buf.string.should.include @msg1
    @buf.string.should.not.include @msg2
  end
end
