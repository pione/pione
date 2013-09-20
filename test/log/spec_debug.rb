require_relative '../test-util'

describe "Pione::Log::Debug" do
  before do
    @out = StringIO.new
    @orig = Global.system_logger
    Global.system_logger = Log::PioneSystemLogger.new(@out)
  end

  after do
    Global.system_logger = @orig
    Global.debug_system = false
    Global.debug_rule_engine = false
    Global.debug_communication = false
    Global.debug_presence_notification = false
    Global.debug_ignored_exception = false
  end

  it "should print system debug message" do
    Global.debug_system = true
    Log::Debug.system("XYZ")
    sleep 0.1 while Global.system_logger.queued?
    @out.string.should.include("XYZ")
  end

  it "should print rule-engine debug message" do
    Global.debug_rule_engine = true
    Log::Debug.rule_engine("XYZ")
    sleep 0.1 while Global.system_logger.queued?
    @out.string.should.include("XYZ")
  end

  it "should print communication debug message" do
    Global.debug_communication = true
    Log::Debug.communication("XYZ")
    sleep 0.1 while Global.system_logger.queued?
    @out.string.should.include("XYZ")
  end

  it "should print presence_notification debug message" do
    Global.debug_presence_notification = true
    Log::Debug.presence_notification("XYZ")
    sleep 0.1 while Global.system_logger.queued?
    @out.string.should.include("XYZ")
  end

  it "should print ignored_exception debug message" do
    Global.debug_ignored_exception = true
    Log::Debug.ignored_exception("XYZ")
    sleep 0.1 while Global.system_logger.queued?
    @out.string.should.include("XYZ")
  end
end
