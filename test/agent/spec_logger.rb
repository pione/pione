require_relative '../test-util'

class TestRecord < Pione::Log::ProcessRecord
  set_type :test
  field :uuid
end

class TestLog < Pione::Log::ProcessLog
  set_filter {|record| record.type == :test}
end

describe "Pione::Agent::Logger" do
  before do
    ts = create_tuple_space_server
    @location = Location[Temppath.create]
    @logger = Agent[:logger].start(ts, @location)
    @msg1 = TestRecord.new(uuid: "e07860f6-18f0-4c1a-8a5a-7d9f3353c83f")
    @msg2 = TestRecord.new(uuid: "c8fa705d-fc30-42fa-a05f-a2493717dc39")
  end

  after do
    @logger.terminate
  end

  it "should get locations" do
    @logger.log_location.should == @location
    @logger.output_location.should == @location
  end

  it "should log messages" do
    write(Tuple[:process_log].new(@msg1))
    write(Tuple[:process_log].new(@msg2))
    @logger.wait_to_clear_logs
    @logger.terminate
    TestLog.read(@location).records.map{|record| record.uuid}.tap do |records|
      records.should.include(@msg1.uuid)
      records.should.include(@msg2.uuid)
    end
  end

  it "should terminate logging by terminate message" do
    # terminate
    write(Tuple[:process_log].new(@msg1))
    @logger.wait_to_clear_logs
    @logger.terminate
    @logger.wait_till(:terminated)
    # write a message after logger was terminated
    write(Tuple[:process_log].new(@msg2))
    TestLog.read(@location).records.map{|record| record.uuid}.tap do |records|
      records.should.include(@msg1.uuid)
    end
  end

  it "should write all records when the logger terminates" do
    1000.times do
      write(Tuple[:process_log].new(@msg1))
    end
    @logger.terminate
    @logger.wait_till(:terminated)
    TestLog.read(@location).records.size.should == 1000
  end
end
