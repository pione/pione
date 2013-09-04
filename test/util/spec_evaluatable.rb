require_relative "../test-util"

module TestEvalator
  extend Pione::Util::Evaluatable
end

describe "Pione::System::Evaluatable" do
  it "should evaluate and get PIONE model object" do
    TestEvalator.val!("1").should == IntegerSequence.of(1)
    TestEvalator.val!('"A"').should == StringSequence.of("A")
  end

  it "should evaluate and get the result string" do
    TestEvalator.val("1").should == "1"
    TestEvalator.val('"A"').should == "A"
  end
end

