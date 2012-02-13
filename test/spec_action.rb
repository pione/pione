require 'innocent-white/process-handler'

include InnocentWhite
Thread.abort_on_exception = true

describe "Action" do
  before do
  end

  it "should action" do
    content = <<-__ACTION__
      echo -n "aaaaa"
    __ACTION__
    definition = {inputs: [], outputs: [], content: content}
    action = ProcessHandler::Action.define(definition)
    action.new([]).execute.should.equal "aaaaa"
  end

  it "should expand variables" do
    content = <<-__ACTION__
      echo -n {$A} {$ABC}
    __ACTION__
    definition = {inputs: [], outputs: [], content: content}
    klass = ProcessHandler::Action.define(definition)
    action = klass.new()
    action.variable["A"] = 123
    action.variable["ABC"] = "abc"
    action.execute.should.equal "123 abc"
  end
end
