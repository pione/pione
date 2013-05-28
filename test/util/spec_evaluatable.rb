require_relative "../test-util"

module TestEvalator
  extend Pione::Util::Evaluatable
end

describe "Pione::System::Evaluatable" do
  it "should evaluate and get PIONE model object" do
    TestEvalator.eval!("1").should == PioneInteger.new(1).to_seq
    TestEvalator.eval!('"A"').should == PioneString.new("A").to_seq
  end

  it "should evaluate and get the result string" do
    TestEvalator.eval("1").should == "1"
    TestEvalator.eval('"A"').should == "A"
  end
end

