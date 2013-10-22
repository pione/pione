require 'pione/test-helper'

TestHelper.scope do |this|
  class this::TestProfileReport1 < Util::ProfileReport
    define_name "test1"
    define_header("header1") {"value1"}
    define_header("header2") {"value2"}
    define_header("header3") {"value3"}
  end

  class this::TestClass
    def initialize(report)
      Util::Profiler.profile(report) do
        @executed = true
      end
    end

    def executed?
      @executed
    end
  end

  describe Pione::Util::Profiler do
    before do
      Global.profile_report_directory = Temppath.mkdir
      Util::Profiler.init
    end

    it "should execute code with profile" do
      # execute with profile
      Util::Profiler.targets.push("test1")
      obj = this::TestClass.new(this::TestProfileReport1.new)
      Util::Profiler.targets.delete("test1")
      obj.should.executed

      # check the report
      Util::Profiler.write_reports
      Location[Global.profile_report_directory].file_entries do |entry|
        entry.size.should > 0
      end
    end

    it "should execute code without profile" do
      # execute without profile
      obj = this::TestClass.new(this::TestProfileReport1.new)
      obj.should.executed

      # check the report
      Util::Profiler.write_reports
      Location[Global.profile_report_directory].file_entries.to_a.size.should == 0
    end
  end
end
