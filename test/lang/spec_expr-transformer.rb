require_relative '../test-util'

$a = Lang::PioneString.new("a")
$b = Lang::PioneString.new("b")
$c = Lang::PioneString.new("c")
$abc = Lang::PioneString.new("abc")
$var_x = Lang::Variable.new("X")
$var_y = Lang::Variable.new("Y")
$var_z = Lang::Variable.new("Z")

describe 'Pione::Transformer::ExprTransformer' do
  transformer_spec("binary operator", :expr) do
    test "1 + 2" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "+"
      msg.receiver.should == Lang::IntegerSequence.of(1)
      msg.arguments.size.should == 1
      msg.arguments[0].should == Lang::IntegerSequence.of(2)
    end

    test '"a" + "b"' do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "+"
      msg.receiver.should == Lang::StringSequence.new([$a])
      msg.arguments.size.should == 1
      msg.arguments[0].should == Lang::StringSequence.new([$b])
    end

    test "false || true" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "||"
      msg.receiver.should == Lang::BooleanSequence.of(false)
      msg.arguments.size.should == 1
      msg.arguments[0].should == Lang::BooleanSequence.of(true)
    end

    test "$X * 3" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "*"
      msg.receiver.should == $var_x
      msg.arguments.size.should == 1
      msg.arguments[0].should == Lang::IntegerSequence.of(3)
    end

    test "($X == \"a\") && ($Y == \"b\")" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "&&"
      msg.receiver.should == Lang::Message.new("==", $var_x, [Lang::StringSequence.new([$a])])
      msg.arguments.size.should == 1
      msg.arguments[0].should == Lang::Message.new("==", $var_y, [Lang::StringSequence.new([$b])])
    end
  end

  transformer_spec("message", :expr) do
    test "1.next" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "next"
      msg.receiver.should == Lang::IntegerSequence.of(1)
      msg.arguments.should.empty
    end

    test "1.next.next" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "next"
      msg.receiver.tap do |rec|
        rec.should.kind_of Lang::Message
        rec.name.should == "next"
        rec.receiver.should == Lang::IntegerSequence.of(1)
        rec.arguments.should.empty
      end
      msg.arguments.should.empty
    end

    test "\"abc\".index(1,1)" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "index"
      msg.receiver.should == Lang::StringSequence.new([$abc])
      msg.arguments.size.should == 2
      msg.arguments[0].should == Lang::IntegerSequence.of(1)
      msg.arguments[1].should == Lang::IntegerSequence.of(1)
    end

    test "(1 + 2).prev" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "prev"
      msg.receiver.tap do |rec|
        rec.should.kind_of Lang::Message
        rec.name.should == "+"
        rec.receiver.should == Lang::IntegerSequence.of(1)
        rec.arguments.size.should == 1
        rec.arguments[0].should == Lang::IntegerSequence.of(2)
      end
      msg.arguments.should.empty
    end

    test "Test.as_string" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "as_string"
      msg.receiver.should == Lang::RuleExprSequence.of("Test")
      msg.arguments.should.empty
    end

    test "'*.txt'.all" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "all"
      msg.receiver.should == Lang::DataExprSequence.of("*.txt")
      msg.arguments.should.empty
    end

    test "'*.txt'.all()" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "all"
      msg.receiver.should == Lang::DataExprSequence.of("*.txt")
      msg.arguments.should.empty
    end

    test "'*.txt'.all(true)" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "all"
      msg.receiver.should == Lang::DataExprSequence.of("*.txt")
      msg.arguments.size.should == 1
      msg.arguments[0].should == Lang::BooleanSequence.of(true)
    end

    test "$var[1]" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "[]"
      msg.receiver.should == Lang::Variable.new("var")
      msg.arguments.size.should == 1
      msg.arguments[0].should == Lang::IntegerSequence.of(1)
    end

    test "$var[1, 2]" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "[]"
      msg.receiver.should == Lang::Variable.new("var")
      msg.arguments.size.should == 2
      msg.arguments[0].should == Lang::IntegerSequence.of(1)
      msg.arguments[1].should == Lang::IntegerSequence.of(2)
    end

    test "not :: true" do |msg|
      msg.should.kind_of Lang::Message
      msg.name.should == "not"
      msg.receiver.should == Lang::BooleanSequence.of(true)
      msg.arguments.should.empty
    end
  end
end
