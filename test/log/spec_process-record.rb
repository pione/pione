require 'pione/test-helper'

module SpecProcessRecord
  class TestRecord < Pione::Log::ProcessRecord
    set_type :test
    field :a
    field :b
    field :c
  end
end

describe "Pione::Log::ProcessRecord" do
  before do
    @record = Log::ProcessRecord.build({type: :test, a: "a", b: "b", c: "c"})
  end

  it "should build a typed record" do
    @record.should.kind_of(SpecProcessRecord::TestRecord)
  end

  it "should get the type" do
    SpecProcessRecord::TestRecord.type.should == :test
  end

  it "should get fields" do
    SpecProcessRecord::TestRecord.fields.sort.should == [:a, :b, :c, :transition, :timestamp, :log_id].sort
  end

  it "should merge" do
    @record.merge(a: "A", b: "B").tap do |x|
      @recored.should != x
      x.a.should == "A"
      x.b.should == "B"
      x.c.should == "c"
      x.timestamp.should == @record.timestamp
      x.transition.should == @record.transition
    end
  end
end

shared "process record" do
  it "should get the type" do
    @record.type.should == @record.class.type
  end

  it "should get field values" do
    @record.fields.each do |field|
      @record.__send__(field).should == @data[field]
    end
  end

  it "should be enable to convert into JSON format" do
    should.not.raise do
      @record.format(Time.now.iso8601(3))
    end
  end
end

describe "Pione::Log::CreateChildTaskWorkerProcessRecord" do
  before do
    @data = {
      parent: "a",
      child: "b",
      timestamp: Time.now,
      transition: "start"
    }
    @record = Log::CreateChildTaskWorkerProcessRecord.new(@data)
  end

  behaves_like "process record"
end

describe "Pione::Log::PutDataProcessRecord" do
  before do
    @data = {
      agent_type: "a",
      agent_uuid: "b",
      location: "c",
      size: 123,
      timestamp: Time.now,
      transition: "start"
    }
    @record = Log::PutDataProcessRecord.new(@data)
  end

  behaves_like "process record"
end

describe "Pione::Log::AgentActivityProcessRecord" do
  before do
    @data = {
      agent_type: "a",
      agent_uuid: "b",
      state: "c",
      timestamp: Time.now,
      transition: "start"
    }
    @record = Log::AgentActivityProcessRecord.new(@data)
  end

  behaves_like "process record"
end

describe "Pione::Log::AgentConnectionProcessRecord" do
  before do
    @data = {
      agent_type: "a",
      agent_uuid: "b",
      message: "c",
      timestamp: Time.now,
      transition: "start"
    }
    @record = Log::AgentConnectionProcessRecord.new(@data)
  end

  behaves_like "process record"
end

describe "Pione::Log::RuleProcessRecord" do
  before do
    @data = {
      name: "a",
      rule_type: "b",
      caller: "c",
      timestamp: Time.now,
      transition: "start"
    }
    @record = Log::RuleProcessRecord.new(@data)
  end

  behaves_like "process record"
end

describe "Pione::Log::TaskProcessRecord" do
  before do
    @data = {
      name: "a",
      rule_name: "b",
      rule_type: "c",
      inputs: "d",
      parameters: "e",
      timestamp: Time.now,
      transition: "start"
    }
    @record = Log::TaskProcessRecord.new(@data)
  end

  behaves_like "process record"
end

