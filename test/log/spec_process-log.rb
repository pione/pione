require_relative '../test-util'

raw_process_log = Pione::Location[File.join(File.dirname(__FILE__), "raw-process-log", "pione-process.log")]

class TestRecord < Pione::Log::ProcessRecord
  set_type :test
  field :a
  field :b
  field :c
end

class TestLog < Pione::Log::ProcessLog
  def format
    @records.map{|record| "%s, %s, %s" % [record.a, record.b, record.c]}.join("\n")
  end
end

describe "Pione::Log::ProcessLog" do
  before do
    @record1 = TestRecord.new(a: 1, b: 2, c: 3)
    @record2 = TestRecord.new(a: 1, b: 1, c: 1)
    @record3 = TestRecord.new(a: 3, b: 2, c: 1)
    @records = [@record1, @record2, @record3]
    @log = TestLog.new(@records)
  end

  it "should make groups by keys" do
    @log.group_by(:a).tap do |x|
      x[1].should.include(@record1)
      x[1].should.include(@record2)
      x[3].should.include(@record3)
    end
    @log.group_by(:b).tap do |x|
      x[2].should.include(@record1)
      x[1].should.include(@record2)
      x[2].should.include(@record3)
    end
    @log.group_by(:c).tap do |x|
      x[3].should.include(@record1)
      x[1].should.include(@record2)
      x[1].should.include(@record3)
    end
  end

  it "should format" do
    @log.format.split("\n").tap do |x|
      x.should.include("1, 2, 3")
      x.should.include("1, 1, 1")
      x.should.include("3, 2, 1")
    end
  end
end

shared "record type filter" do
  it "should select target type records" do
    @log.values.each do |log|
      log.records.should.all{|record| record.type == @type}
    end
  end
end

describe "Pione::Log::AgentActivityLog" do
  before do
    @type = :agent_activity
    @log = Log::AgentActivityLog.read(raw_process_log)
  end

  behaves_like "record type filter"
end

describe "Pione::Log::RuleProcessLog" do
  before do
    @type = :rule_process
    @log = Log::RuleProcessLog.read(raw_process_log)
  end

  behaves_like "record type filter"
end

describe "Pione::Log::TaskProcessLog" do
  before do
    @type = :task_process
    @log = Log::TaskProcessLog.read(raw_process_log)
  end

  behaves_like "record type filter"
end



