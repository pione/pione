require 'pione/test-helper'
require_relative 'command-behavior'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data" + "pione-client"

  describe Pione::Command::PioneClient do
    before do
      @cmd = Command::PioneClient
    end

    behaves_like "command"

    it "should execute a PIONE document" do
      path = Temppath.create
      cmd = @cmd.new(["example/HelloWorld/HelloWorld.pione", "-o", path.to_s])
      res = Rootage::ScenarioTest.succeed(cmd)
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE document with stand alone mode" do
      path = Temppath.create
      cmd = @cmd.new(["example/HelloWorld/HelloWorld.pione", "-o", path.to_s, "--stand-alone"])
      Rootage::ScenarioTest.succeed(cmd)
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE package" do
      path = Temppath.create
      cmd = @cmd.new(["example/HelloWorld/", "-o", path.to_s])
      Rootage::ScenarioTest.succeed(cmd)
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE package with stand alone mode" do
      path = Temppath.create
      cmd = @cmd.new(["example/HelloWorld/", "-o", path.to_s, "--stand-alone"])
      Rootage::ScenarioTest.succeed(cmd)
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should fail with action error" do
      doc = (this::DIR + "ActionError.pione").path.to_s
      path = Temppath.create
      cmd = @cmd.new([doc, "-o", path.to_s, "--stand-alone"])
      Rootage::ScenarioTest.fail(cmd)
    end

    describe "example/Fib" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result with no parameters (default fib(3))"
        runner.args = ["example/Fib/Fib.pione", *runner.default_arguments]
        runner.run do |base|
          (base + "result.txt").should.exist
          (base + "result.txt").read.should.start_with "2"
        end
      end

      # FIXME: this test is unstable... maybe there are bugs

      # it "should get a result of fib(10)" do
      #   path = Temppath.create
      #   args = ["example/Fib/Fib.pione", "-o", path.to_s, "--params", "{NUM: 10}"]
      #   res = TestHelper::Command.succeed do
      #     Pione::Command::PioneClient.run(args)
      #   end
      #   Location[path + "result.txt"].should.exist
      #   Location[path + "result.txt"].read.should.start_with "55"
      # end
    end

    describe "example/PegasusWMS/Merge" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of example/PegasusWMS/Merge"
        runner.args = ["example/PegasusWMS/Merge/", *runner.default_arguments]
        runner.run do |base|
          (base + "binaries.txt").should.exist
          (base + "binaries.txt").size.should > 0
        end
      end
    end

    describe "example/PegasusWMS/Pipeline" do
      if TestHelper::InternetConnectivity.ok?
        TestHelper::PioneClientRunner.test(self) do |runner|
          runner.title = "should get a result of example/PegasusWMS/Pipeline"
          runner.args = ["example/PegasusWMS/Pipeline/", *runner.default_arguments]
          runner.run do |base|
            (base + "count.txt").should.exist
            (base + "count.txt").size.should > 0
          end
        end
      else
        puts "    * ignored because of no internet connection"
      end
    end

    describe "example/PegasusWMS/Split" do
      if TestHelper::InternetConnectivity.ok?
        TestHelper::PioneClientRunner.test(self) do |runner|
          runner.title = "should get a result of example/PegasusWMS/Split"
          runner.args = ["example/PegasusWMS/Split/", *runner.default_arguments]
          runner.run do |base|
            (base + "count.txt.a").should.exist
            (base + "count.txt.a").size.should > 0
            (base + "count.txt.b").should.exist
            (base + "count.txt.b").size.should > 0
            (base + "count.txt.c").should.exist
            (base + "count.txt.c").size.should > 0
            (base + "count.txt.d").should.exist
            (base + "count.txt.d").size.should > 0
          end
        end
      else
        puts "    * ignored because of no internet connection"
      end
    end

    describe "example/OddSelector" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of example/OddSelector"
        runner.args = ["example/OddSelector", "--rehearse", *runner.default_arguments]
        runner.run do |base|
          (base + "1.res").should.exist
          (base + "2.res").should.not.exist
          (base + "3.res").should.exist
          (base + "4.res").should.not.exist
          (base + "5.res").should.exist
          (base + "6.res").should.not.exist
          (base + "7.res").should.exist
          (base + "8.res").should.not.exist
          (base + "9.res").should.exist
          (base + "10.res").should.not.exist
        end
      end
    end

    describe "example/SerialProcessing" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of example/SerialProcessing"
        runner.args = ["example/SerialProcessing", "--rehearse", *runner.default_arguments]
        runner.run do |base|
          (base + "1.a").should.exist
          (base + "2.a").should.exist
          (base + "3.a").should.exist
          (base + "4.a").should.exist
          (base + "1.b").should.exist
          (base + "2.b").should.exist
          (base + "3.b").should.exist
          (base + "4.b").should.exist
          (base + "1.a").mtime.should <= (base + "2.a").mtime
          (base + "2.a").mtime.should <= (base + "3.a").mtime
          (base + "3.a").mtime.should <= (base + "4.a").mtime
          (base + "4.a").mtime.should <= (base + "1.b").mtime
          (base + "1.b").mtime.should <= (base + "2.b").mtime
          (base + "2.b").mtime.should <= (base + "3.b").mtime
          (base + "3.b").mtime.should <= (base + "4.b").mtime
        end
      end
    end

    describe "example/MakePair" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of example/MakePair"
        runner.args = ["example/MakePair", "--rehearse", "case1", *runner.default_arguments]
        runner.run do |base|
          1.upto(5) do |i|
            1.upto(5) do |ii|
              comb = (base + "comb-%s-%s.pair" % [i, ii])
              i < ii ? comb.should.exist : comb.should.not.exist
              perm = (base + "perm-%s-%s.pair" % [i, ii])
              i != ii ? perm.should.exist : perm.should.not.exist
              succ = (base + "succ-%s-%s.pair" % [i, ii])
              ii - i == 1 ? succ.should.exist : succ.should.not.exist
            end
          end
        end
      end
    end

    describe "example/SelectRuleByParam" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of scenario a of example/SelectRuleByParam"
        runner.args = ["example/SelectRuleByParam", "--rehearse", "Select A", *runner.default_arguments]
        runner.run do |base|
          (base + "message.txt").should.exist
          (base + "message.txt").read.chomp.should == "This is rule A."
        end
      end

      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of scenario b of example/SelectRuleByParam"
        runner.args = ["example/SelectRuleByParam", "--rehearse", "Select B", *runner.default_arguments]
        runner.run do |base|
          (base + "message.txt").should.exist
          (base + "message.txt").read.chomp.should == "This is rule B."
        end
      end

      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of scenario c of example/SelectRuleByParam"
        runner.args = ["example/SelectRuleByParam", "--rehearse", "Select C", *runner.default_arguments]
        runner.run do |base|
          (base + "message.txt").should.exist
          (base + "message.txt").read.chomp.should == "This is rule C."
        end
      end
    end

    describe "example/FeatureExample" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of example/FeatureExample"
        runner.args = ["example/FeatureExample", "--feature", "^X", *runner.default_arguments]
        runner.run do |base|
          (base + "message.txt").should.exist
          (base + "message.txt").read.chomp.should == "I can take the task."
        end
      end

      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should timeout with feature `*` in processing example/FeatureExample"
        runner.args = ["example/FeatureExample", "--feature", "*", *runner.default_arguments]
        runner.timeout(5)
      end
    end

    describe "example/Sum" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should get a result of example/Sum"
        runner.args = ["example/Sum", "--rehearse", *runner.default_arguments]
        runner.run do |base|
          (base + "sum.txt").should.exist
        end
      end
    end

    describe "example/ActionError" do
      TestHelper::PioneClientRunner.test(self) do |runner|
        runner.title = "should fail in execution of example/ActionError"
        runner.args = ["example/ActionError", *runner.default_arguments]
        runner.fail
      end
    end
  end
end
