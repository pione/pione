require 'innocent-white/process-handler'

describe "Action" do
  before do
    @action = InnocentWhite::ProcessHandler::Action.new
  end

  it "should action" do
    @action.content = <<-__ACTION__
      echo -n "aaaaa"
    __ACTION__
    @action.execute.should.equal "aaaaa"
  end

  it "should expand variables" do
    @action.variable["A"] = 123
    @action.variable["ABC"] = "abc"
    @action.content = <<-__ACTION__
      echo -n {$A} {$ABC}
    __ACTION__
    @action.execute.should.equal "123 abc"
  end
end
