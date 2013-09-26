require 'pione/test-helper'
require_relative 'command-behavior'

describe "Pione::Command::PioneClient" do
  behaves_like "command"

  ### is this wrong?
  # it "should execute a PIONE document" do
  #   path = Temppath.create
  #   args = ["example/HelloWorld/HelloWorld.pione", "-o", path.to_s]
  #   res = TestHelper::Command.succeed do
  #     Pione::Command::PioneClient.run args
  #   end
  #   Location[path + "message.txt"].should.exist
  #   Location[path + "message.txt"].read.should.start_with "Hello, world!"
  # end

  it "should execute a PIONE document with stand alone mode" do
    path = Temppath.create
    args = ["example/HelloWorld/HelloWorld.pione", "-o", path.to_s, "--stand-alone"]
    res = TestHelper::Command.succeed do
      Pione::Command::PioneClient.run args
    end
    Location[path + "message.txt"].should.exist
    Location[path + "message.txt"].read.should.start_with "Hello, world!"
  end

  # it "should execute a PIONE package" do
  #   path = Temppath.create
  #   args = ["example/HelloWorld/", "-o", path.to_s]
  #   res = TestHelper::Command.succeed do
  #     Pione::Command::PioneClient.run args
  #   end
  #   Location[path + "message.txt"].should.exist
  #   Location[path + "message.txt"].read.should.start_with "Hello, world!"
  # end

  it "should execute a PIONE package with stand alone mode" do
    path = Temppath.create
    args = ["example/HelloWorld/", "-o", path.to_s, "--stand-alone"]
    res = TestHelper::Command.succeed do
      Pione::Command::PioneClient.run args
    end
    Location[path + "message.txt"].should.exist
    Location[path + "message.txt"].read.should.start_with "Hello, world!"
  end

  it "should show parameters list of package" do
    args = ["example/HelloWorld/HelloWorld.pione", "--list-params"]
    res = TestHelper::Command.succeed do
      Pione::Command::PioneClient.run args
    end
    res.stdout.string.size.should > 0
  end
end

