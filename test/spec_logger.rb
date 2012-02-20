require 'stringio'
require 'innocent-white/agent/logger'

include InnocentWhite
Thread.abort_on_exception = true
DRb.start_service

describe "Logger" do
  before do
    @remote_server = DRb.start_service(nil, TupleSpaceServer.new(task_worker_resource: 3))
    @ts_server = DRbObject.new(nil, @remote_server.uri)
    @buf = StringIO.new("", "w+")
    @logger = Agent::Logger.new(@ts_server, @buf)
  end

  it "should log" do
    @ts_server.write(Tuple[:log].new(:debug, "asfdasfasfaweqrqwerqwre"))
    @ts_server.write(Tuple[:log].new(:info, "asl;jfa;lsdflkgaosdfasl;afl"))
    sleep 0.1
    @ts_server.read_all(Tuple[:log].any).size.should == 0
    @buf.string.split("\n").should.include "debug: asfdasfasfaweqrqwerqwre"
    @buf.string.split("\n").should.include "info: asl;jfa;lsdflkgaosdfasl;afl"
  end

  it "should terminate logging by terminate message" do
    sleep 0.1
    @logger.should.be.logging
    @logger.terminate
    sleep 0.1
    @logger.should.be.terminated
    @ts_server.write(Tuple[:log].new(:debug, "gasldkfjals;dfjlak;flsd"))
    sleep 0.2
    @buf.string.split("\n").should.not.include "debug: gasldkfjals;dfjlak;flsd"
  end

  it "should terminate logging by exception" do
    @ts_server.write(Tuple[:log].new(:warn, "asdfasgagaskjlhkj"))
    @remote_server.stop_service
    @ts_server.write(Tuple[:log].new(:warn, "asdfasgagaskjlhkj2"))
    @ts_server.all_tuples
    p @ts_server
    p @buf.string
    p @remote_server.alive?
    sleep 0.1
    @logger.should.be.terminated
  end

end

