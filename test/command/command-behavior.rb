shared "command" do
  it "should show a help message" do
    res = TestUtil::Command.succeed do
      Command::PioneVal.run ["--help"]
    end
    res.stdout.string.should.start_with "Usage"
  end

  it "should show a version message" do
    res = TestUtil::Command.succeed do
      Command::PioneVal.run ["--version"]
    end
    res.stdout.string.should.include Pione::VERSION
  end
end
