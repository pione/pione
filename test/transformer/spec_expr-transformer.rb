require_relative '../test-util'

$a = PioneString.new("a")
$b = PioneString.new("b")
$c = PioneString.new("c")
$abc = PioneString.new("abc")
$var_x = Variable.new("X")
$var_y = Variable.new("Y")
$var_z = Variable.new("Z")

describe 'Pione::Transformer::ExprTransformer' do
  transformer_spec("binary operator", :expr) do
    test "1 + 2" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "+"
      msg.receiver.should == IntegerSequence.of(1)
      msg.arguments.size.should == 1
      msg.arguments[0].should == IntegerSequence.of(2)
    end

    test '"a" + "b"' do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "+"
      msg.receiver.should == StringSequence.new([$a])
      msg.arguments.size.should == 1
      msg.arguments[0].should == StringSequence.new([$b])
    end

    test "false || true" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "||"
      msg.receiver.should == BooleanSequence.of(false)
      msg.arguments.size.should == 1
      msg.arguments[0].should == BooleanSequence.of(true)
    end

    test "$X * 3" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "*"
      msg.receiver.should == $var_x
      msg.arguments.size.should == 1
      msg.arguments[0].should == IntegerSequence.of(3)
    end

    test "($X == \"a\") && ($Y == \"b\")" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "&&"
      msg.receiver.should == Message.new("==", $var_x, StringSequence.new([$a]))
      msg.arguments.size.should == 1
      msg.arguments[0].should == Message.new("==", $var_y, StringSequence.new([$b]))
    end
  end

  transformer_spec("data_expr", :expr) do
    test "'test.a'" do |data_expr|
      data_expr.should == DataExpr.new("test.a").to_seq
    end

    test "null" do |data_expr|
      data_expr.should == DataExprNull.instance.to_seq
    end
  end

  transformer_spec("message", :expr) do
    test "1.next" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "next"
      msg.receiver.should == IntegerSequence.of(1)
      msg.arguments.should.empty
    end

    test "1.next.next" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "next"
      msg.receiver.tap do |rec|
        rec.should.kind_of Model::Message
        rec.name.should == "next"
        rec.receiver.should == IntegerSequence.of(1)
        rec.arguments.should.empty
      end
      msg.arguments.should.empty
    end

    test "\"abc\".index(1,1)" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "index"
      msg.receiver.should == StringSequence.new([$abc])
      msg.arguments.size.should == 2
      msg.arguments[0].should == IntegerSequence.of(1)
      msg.arguments[1].should == IntegerSequence.of(1)
    end

    test "(1 + 2).prev" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "prev"
      msg.receiver.tap do |rec|
        rec.should.kind_of Model::Message
        rec.name.should == "+"
        rec.receiver.should == IntegerSequence.of(1)
        rec.arguments.size.should == 1
        rec.arguments[0].should == IntegerSequence.of(2)
      end
      msg.arguments.should.empty
    end

    test "Test.as_string" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "as_string"
      msg.receiver.should == RuleExpr.new(PackageExpr.new("Main"), "Test")
      msg.arguments.should.empty
    end

    test "'*.txt'.all" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "all"
      msg.receiver.should == DataExpr.new("*.txt").to_seq
      msg.arguments.should.empty
    end

    test "'*.txt'.all()" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "all"
      msg.receiver.should == DataExpr.new("*.txt").to_seq
      msg.arguments.should.empty
    end

    test "'*.txt'.all(true)" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "all"
      msg.receiver.should == DataExpr.new("*.txt").to_seq
      msg.arguments.size.should == 1
      msg.arguments[0].should == BooleanSequence.of(true)
    end

    test "$var[1]" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "[]"
      msg.receiver.should == Model::Variable.new("var")
      msg.arguments.size.should == 1
      msg.arguments[0].should == IntegerSequence.of(1)
    end

    test "$var[1, 2]" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "[]"
      msg.receiver.should == Model::Variable.new("var")
      msg.arguments.size.should == 2
      msg.arguments[0].should == IntegerSequence.of(1)
      msg.arguments[1].should == IntegerSequence.of(2)
    end

    test "not :: true" do |msg|
      msg.should.kind_of Model::Message
      msg.name.should == "not"
      msg.receiver.should == BooleanSequence.of(true)
      msg.arguments.should.empty
    end
  end

  transformer_spec("parameters", :expr) do
    tc "{}" do
      Parameters.new({})
    end

    tc "{X: 1}" do
      Parameters.new({$var_x => IntegerSequence.of(1)})
    end

    tc "{X: 1, Y: 2}" do
      Parameters.new(
        { $var_x => IntegerSequence.of(1),
          $var_y => IntegerSequence.of(2) }
      )
    end

    tc "{X: \"a\", Y: \"b\", Z: \"c\"}" do
      Parameters.new(
        { $var_x => StringSequence.new([$a]),
          $var_y => StringSequence.new([$b]),
          $var_z => StringSequence.new([$c]) }
      )
    end
  end
end
