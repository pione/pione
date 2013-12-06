shared "command" do
  it "should show a help message" do
    res = TestHelper::Command.succeed(@cmd, ["--help"])
    res.stdout.string.should.start_with "Usage"
  end

  it "should show a version message" do
    res = TestHelper::Command.succeed(@cmd, ["--version"])
    res.stdout.string.should.include Pione::VERSION
  end
end
