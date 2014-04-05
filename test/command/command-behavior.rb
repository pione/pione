shared "command" do
  it "should show a help message" do
    cmd = @cmd.new(["--help"])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.size.should > 0
  end
end
