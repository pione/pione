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
    tc "1 + 2" do
      Message.new(
        "+",
        IntegerSequence.new([1.to_pione]),
        IntegerSequence.new([2.to_pione])
      )
    end

    tc '"a" + "b"' do
      Message.new("+", StringSequence.new([$a]), StringSequence.new([$b]))
    end

    tc "false || true" do
      Message.new(
        "||",
        BooleanSequence.new([PioneBoolean.false]),
        BooleanSequence.new([PioneBoolean.true])
      )
    end

    tc "$X * 3" do
      Message.new("*", $var_x, IntegerSequence.new([3.to_pione]))
    end

    tc "($X == \"a\") && ($Y == \"b\")" do
      left = Message.new("==", $var_x, StringSequence.new([$a]))
      right = Message.new("==", $var_y, StringSequence.new([$b]))
      Message.new("&&", left, right)
    end
  end

  transformer_spec("data_expr", :expr) do
    tc "'test.a'" do
      DataExpr.new("test.a").to_seq
    end

    tc "null" do
      DataExprNull.instance.to_seq
    end
  end

  transformer_spec("message", :expr) do
    tc "1.next" do
      Message.new("next", IntegerSequence.new([1.to_pione]))
    end

    tc "1.next.next" do
      Message.new("next", Message.new("next", IntegerSequence.new([1.to_pione])))
    end

    tc "\"abc\".index(1,1)" do
      Message.new(
        "index",
        StringSequence.new([$abc]),
        IntegerSequence.new([1.to_pione]),
        IntegerSequence.new([1.to_pione])
      )
    end

    tc "(1 + 2).prev" do
      Message.new(
        "prev",
        Message.new(
          "+",
          IntegerSequence.new([1.to_pione]),
          IntegerSequence.new([2.to_pione])
        )
      )
    end

    tc "abc.sync" do
      rule = RuleExpr.new(PackageExpr.new("main"), "abc")
      Message.new("sync", rule)
    end

    tc "'*.txt'.all" do
      Message.new("all", DataExpr.new("*.txt").to_seq)
    end

    tc "'*.txt'.all()" do
      Message.new("all", DataExpr.new("*.txt").to_seq)
    end

    tc "'*.txt'.all(true)" do
      Message.new("all", DataExpr.new("*.txt").to_seq, BooleanSequence.new([PioneBoolean.true]))
    end
  end

  transformer_spec("parameters", :expr) do
    tc "{}" do
      Parameters.new({})
    end

    tc "{X: 1}" do
      Parameters.new({$var_x => IntegerSequence.new([PioneInteger.new(1)])})
    end

    tc "{X: 1, Y: 2}" do
      Parameters.new(
        { $var_x => IntegerSequence.new([PioneInteger.new(1)]),
          $var_y => IntegerSequence.new([PioneInteger.new(2)]) }
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
