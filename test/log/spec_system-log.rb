require_relative '../test-util'

class TestLogger < Log::SystemLogger
  forward :@out, :puts, :fatal
  forward :@out, :puts, :error
  forward :@out, :puts, :warn
  forward :@out, :puts, :info
  forward :@out, :puts, :debug
  forward Proc.new{ @out.string }, :include?

  def initialize
    @out = StringIO.new
  end
end

describe "Pione::Log::SystemLogger" do
  it "should log the fatal message" do
    TestLogger.new.tap{|x| x.fatal "XYZ"}.should.include("XYZ")
  end

  it "should log the error message" do
    TestLogger.new.tap{|x| x.error "XYZ"}.should.include("XYZ")
  end

  it "should log the warn message" do
    TestLogger.new.tap{|x| x.warn "XYZ"}.should.include("XYZ")
  end

  it "should log the info message" do
    TestLogger.new.tap{|x| x.info "XYZ"}.should.include("XYZ")
  end

  it "should log the debug message" do
    TestLogger.new.tap{|x| x.debug "XYZ"}.should.include("XYZ")
  end
end

shared "system logger" do
  it "should log the fatal message" do
    @logger.fatal "fatal message"
    sleep 0.1 while @logger.queued?
    @out.string.should.include("fatal message")
  end

  it "should log the error message" do
    @logger.error "error message"
    sleep 0.1 while @logger.queued?
    @out.string.should.include("error message")
  end

  it "should log the warn message" do
    @logger.warn "warn message"
    sleep 0.1 while @logger.queued?
    @out.string.should.include("warn message")
  end

  it "should log the info message" do
    @logger.info "info message"
    sleep 0.1 while @logger.queued?
    @out.string.should.include("info message")
  end

  it "should log the debug message" do
    @logger.debug "debug message"
    sleep 0.1 while @logger.queued?
    @out.string.should.include("debug message")
  end
end

describe "Pione::Log::PioneSystemLogger" do
  before do
    @out = StringIO.new
    @logger = Log::PioneSystemLogger.new(@out)
  end

  after do
    @logger.terminate
  end

  behaves_like "system logger"
end

describe "Pione::Log::RubyStandardSystemLogger" do
  before do
    @out = StringIO.new
    @logger = Log::RubyStandardSystemLogger.new(@out)
  end

  behaves_like "system logger"
end

module MockSyslog
  @out = StringIO.new

  class << self
    attr_reader :out

    Logger::Syslog::LOGGER_MAP.values.uniq.each do |level|
      define_method(level) do |message|
        @out.puts "%s - %s" % [level.to_s, message]
      end
    end

    def reset
      @out = StringIO.new
    end
  end
end

Logger::Syslog.const_set :SYSLOG, MockSyslog

describe "Pione::Log::SyslogSystemLogger" do
  before do
    @out = MockSyslog.out
    @logger = Log::SyslogSystemLogger.new
  end

  after do
    MockSyslog.reset
  end

  behaves_like "system logger"
end

describe "Pione::Log::SystemLog" do
  before do
    @orig = Global.system_logger
    @logger = TestLogger.new
    Global.system_logger = @logger
  end

  after do
    Global.system_logger = @orig
  end

  it "should log the fatal message" do
    Log::SystemLog.fatal("This is a fatal message.")
    @logger.should.include("This is a fatal message.")
  end

  it "should log the error message" do
    Log::SystemLog.fatal("This is an error message.")
    @logger.should.include("This is an error message.")
  end

  it "should log the warn message" do
    Log::SystemLog.fatal("This is a warn message.")
    @logger.should.include("This is a warn message.")
  end

  it "should log the info message" do
    Log::SystemLog.fatal("This is an info message.")
    @logger.should.include("This is an info message.")
  end

  it "should log the debug message" do
    Log::SystemLog.fatal("This is a debug message.")
    @logger.should.include("This is a debug message.")
  end
end
