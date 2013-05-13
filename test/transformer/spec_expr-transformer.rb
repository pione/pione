require_relative '../test-util'

describe 'Pione::Transformer::ExprTransformer' do
  transformer_spec("binary operator", :expr) do
    tc "1 + 2" do
      BinaryOperator.new(
        "+",
        IntegerSequence.new([1.to_pione]),
        IntegerSequence.new([2.to_pione])
      )
    end

    tc '"a" + "b"' do
      BinaryOperator.new(
        "+",
        StringSequence.new(["a".to_pione]),
        StringSequence.new(["b".to_pione])
      )
    end

    tc "false || true" do
      BinaryOperator.new(
        "||",
        BooleanSequence.new([PioneBoolean.false]),
        BooleanSequence.new([PioneBoolean.true])
      )
    end

    tc "$Var * 3" do
      BinaryOperator.new(
        "*",
        Variable.new("Var"),
        IntegerSequence.new([3.to_pione])
      )
    end

    tc "($Var1 == \"a\") && ($Var2 == \"b\")" do
      left = BinaryOperator.new(
        "==",
        Variable.new("Var1"),
        StringSequence.new(["a".to_pione])
      )
      right = BinaryOperator.new(
        "==",
        Variable.new("Var2"),
        StringSequence.new([PioneString.new("b")])
      )
      BinaryOperator.new("&&", left, right)
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
        StringSequence.new(["abc".to_pione]),
        IntegerSequence.new([1.to_pione]),
        IntegerSequence.new([1.to_pione])
      )
    end

    tc "(1 + 2).prev" do
      Message.new(
        "prev",
        BinaryOperator.new(
          "+",
          IntegerSequence.new([1.to_pione]),
          IntegerSequence.new([2.to_pione])
        )
      )
    end

    tc "abc.sync" do
      rule = RuleExpr.new(Package.new("main"), "abc")
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

    tc "{var1: 1}" do
      Parameters.new(
        {Variable.new("var1") => IntegerSequence.new([PioneInteger.new(1)])}
      )
    end

    tc "{var1: 1, var2: 2}" do
      Parameters.new(
        { Variable.new("var1") => IntegerSequence.new([PioneInteger.new(1)]),
          Variable.new("var2") => IntegerSequence.new([PioneInteger.new(2)]) }
      )
    end

    tc "{var1: \"a\", var2: \"b\", var3: \"c\"}" do
      Parameters.new(
        { Variable.new("var1") => StringSequence.new([PioneString.new("a")]),
          Variable.new("var2") => StringSequence.new([PioneString.new("b")]),
          Variable.new("var3") => StringSequence.new([PioneString.new("c")]) }
      )
    end
  end
end
