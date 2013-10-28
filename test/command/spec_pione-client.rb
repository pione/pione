require 'pione/test-helper'
require_relative 'command-behavior'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data" + "pione-client"

  describe "Pione::Command::PioneClient" do
    behaves_like "command"

    it "should execute a PIONE document" do
      path = Temppath.create
      args = ["example/HelloWorld/HelloWorld.pione", "-o", path.to_s]
      res = TestHelper::Command.succeed do
        Pione::Command::PioneClient.run(args)
      end
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE document with stand alone mode" do
      path = Temppath.create
      args = ["example/HelloWorld/HelloWorld.pione", "-o", path.to_s, "--stand-alone"]
      TestHelper::Command.succeed do
        Pione::Command::PioneClient.run(args)
      end
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE package" do
      path = Temppath.create
      args = ["example/HelloWorld/", "-o", path.to_s]
      TestHelper::Command.succeed do
        Pione::Command::PioneClient.run(args)
      end
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should execute a PIONE package with stand alone mode" do
      path = Temppath.create
      args = ["example/HelloWorld/", "-o", path.to_s, "--stand-alone"]
      TestHelper::Command.succeed do
        Pione::Command::PioneClient.run(args)
      end
      Location[path + "message.txt"].should.exist
      Location[path + "message.txt"].read.should.start_with "Hello, world!"
    end

    it "should fail with action error" do
      doc = (this::DIR + "ActionError.pione").path.to_s
      path = Temppath.create
      args = [doc, "-o", path.to_s, "--stand-alone"]
      TestHelper::Command.fail do
        Pione::Command::PioneClient.run(args)
      end
    end

    it "should show parameters list of package" do
      args = ["example/HelloWorld/HelloWorld.pione", "--list-params"]
      res = TestHelper::Command.succeed do
        Pione::Command::PioneClient.run(args)
      end
      res.stdout.string.size.should > 0
    end
  end
end
