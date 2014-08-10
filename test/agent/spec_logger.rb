require 'pione/test-helper'

module SpecLogger
  class TestRecord < Pione::Log::ProcessRecord
    set_type :test
    field :uuid
  end

  class TestLog < Pione::Log::ProcessLog
    set_filter {|record| record.type == :test}
  end
end

describe "Pione::Agent::Logger" do
  before do
    @space = TestHelper::TupleSpace.create(self)
    @location = Location[Temppath.create] + "pione-process.log"
    @logger = Agent[:logger].start(@space, @location)
    @msg1 = SpecLogger::TestRecord.new(uuid: "e07860f6-18f0-4c1a-8a5a-7d9f3353c83f")
    @msg2 = SpecLogger::TestRecord.new(uuid: "c8fa705d-fc30-42fa-a05f-a2493717dc39")
  end

  after do
    @logger.terminate
    @space
  end

  it "should get locations" do
    @logger.log_location.should == @location
  end

  it "should log messages" do
    write(TupleSpace::ProcessLogTuple.new(@msg1))
    write(TupleSpace::ProcessLogTuple.new(@msg2))
    sleep 1 # wait to write out tuples
    @logger.terminate
    @logger.wait_until_terminated
    SpecLogger::TestLog.read(@location).values.first.records.map{|record| record.uuid}.tap do |records|
      records.should.include(@msg1.uuid)
      records.should.include(@msg2.uuid)
    end
  end

  it "should terminate logging by terminate message" do
    # terminate
    write(TupleSpace::ProcessLogTuple.new(@msg1))
    sleep 1 # wait to write out the tuple
    @logger.terminate
    @logger.wait_until_terminated
    # write a message after logger was terminated
    write(TupleSpace::ProcessLogTuple.new(@msg2))
    SpecLogger::TestLog.read(@location).values.first.records.map{|record| record.uuid}.tap do |records|
      records.should.include(@msg1.uuid)
    end
  end

  it "should write all records when the logger terminates" do
    1000.times {write(TupleSpace::ProcessLogTuple.new(@msg1))}
    sleep 2
    @logger.terminate
    @logger.wait_until_terminated
    SpecLogger::TestLog.read(@location).values.first.records.size.should == 1000
  end
end
