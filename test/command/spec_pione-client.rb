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
      cmd = @cmd.new(["example/HelloWorld/", "--base", path.to_s])
      res = Rootage::ScenarioTest.succeed(cmd)
      Location[path + "output" + "message.txt"].should.exist
      Location[path + "output" + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE document with stand alone mode" do
      path = Temppath.create
      cmd = @cmd.new(["example/HelloWorld/", "--base", path.to_s, "--stand-alone"])
      Rootage::ScenarioTest.succeed(cmd)
      Location[path + "output" + "message.txt"].should.exist
      Location[path + "output" + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE package" do
      path = Temppath.create
      cmd = @cmd.new(["example/HelloWorld/", "--base", path.to_s])
      Rootage::ScenarioTest.succeed(cmd)
      Location[path + "output" + "message.txt"].should.exist
      Location[path + "output" + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE package with stand alone mode" do
      path = Temppath.create
      cmd = @cmd.new(["example/HelloWorld/", "--base", path.to_s, "--stand-alone"])
      Rootage::ScenarioTest.succeed(cmd)
      Location[path + "output" + "message.txt"].should.exist
      Location[path + "output" + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should fail with action error" do
      doc = (this::DIR + "ActionError.pione").path.to_s
      path = Temppath.create
      cmd = @cmd.new([doc, "--base", path.to_s, "--stand-alone"])
      Rootage::ScenarioTest.fail(cmd)
    end
  end
end
