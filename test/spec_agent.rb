require 'innocent-white/agent'

include InnocentWhite

class TestStatus < AgentStatus
  define_state :test1
  define_sub_state :test1, :test2
  define_state :test3
  define_sub_state :test3, :test4
  define_sub_state :test4, :test5
end

describe "Agent" do
  describe "AgentStatus" do
    it "should raise ArgumentError" do
      should.raise(ArgumentError) {AgentStatus.new(:nil)}
    end

    it "should access state names" do
      TestStatus.test1.should == TestStatus.new(:test1)
      TestStatus.test2.should == TestStatus.new(:test2)
      TestStatus.test3.should == TestStatus.new(:test3)
      TestStatus.test4.should == TestStatus.new(:test4)
      TestStatus.test5.should == TestStatus.new(:test5)
    end

    it "should have predicates" do
      test1 = TestStatus.test1
      test1.should.be.test1
      test1.should.not.be.test2
      test2 = TestStatus.test2
      test2.should.be.test1
      test2.should.be.test2
    end

    it "should change state" do
      test_a = TestStatus.test1
      test_a.should == :test1
      test_a.test2
      test_a.should == :test2
    end

    it "should match other state" do
      test1 = TestStatus.test1
      test2 = TestStatus.test2
      test3 = TestStatus.test3
      test4 = TestStatus.test4
      test5 = TestStatus.test5
      test1.should == test1
      test1.should == :test1
      test1.should.not == :test2
      test1.should.not == :test3
      test1.should.not == :test4
      test1.should.not == :test5
      test2.should.not == :test1
      test2.should == test2
      test2.should == :test2
      test2.should.not == :test3
      test2.should.not == :test4
      test2.should.not == :test5
      test3.should.not == :test1
      test3.should.not == :test2
      test3.should == test3
      test3.should == :test3
      test3.should.not == :test4
      test3.should.not == :test5
      test4.should.not == :test1
      test4.should.not == :test2
      test4.should.not == :test3
      test4.should == test4
      test4.should == :test4
      test4.should.not == :test5
      test5.should.not == :test1
      test5.should.not == :test2
      test5.should.not == :test3
      test5.should.not == :test4
      test5.should == test5
      test5.should == :test5
      test1.should === :test1
      test1.should.not === :test2
      test1.should.not === :test3
      test1.should.not === :test4
      test1.should.not === :test5
      test2.should === :test1
      test2.should === :test2
      test2.should.not === :test3
      test2.should.not === :test4
      test2.should.not === :test5
      test3.should.not === :test1
      test3.should.not === :test2
      test3.should === :test3
      test3.should.not === :test4
      test3.should.not === :test5
      test4.should.not === :test1
      test4.should.not === :test2
      test4.should === :test3
      test4.should === :test4
      test4.should.not === :test5
      test5.should.not === :test1
      test5.should.not === :test2
      test5.should === :test3
      test5.should === :test4
      test5.should === :test5
      case test1
      when :test1; true
      else ; false
      end.should.be.true
      case test2
      when :test1; true
      else; false
      end.should.be.true
    end

    it "should initialized" do
      AgentStatus.new.should == :initialized
    end
  end
end
