require 'pione/test-helper'

describe "example/HelloWorld" do
  before do
    @cmd = Command::PioneClient
  end

  it "should process" do
    path = Temppath.create
    cmd = @cmd.new(["example/HelloWorld/", "--base", path.to_s])
    res = Rootage::ScenarioTest.succeed(cmd)
    Location[path + "output" + "message.txt"].should.exist
    Location[path + "output" + "message.txt"].read.should.start_with "Hello, world!"
  end
end
