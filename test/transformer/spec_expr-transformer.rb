require_relative '../test-util'

describe 'Pione::Transformer::ExprTransformer' do
  transformer_spec("binary operator", :expr) do
    tc "1 + 2" do
      BinaryOperator.new(
        "+",
        PioneInteger.new(1),
        PioneInteger.new(2)
      )
    end
    tc '"a" + "b"' do
      BinaryOperator.new(
        "+",
        PioneString.new("a"),
        PioneString.new("b")
      )
    end
    tc "false || true" do
      BinaryOperator.new(
        "||",
        PioneBoolean.false,
        PioneBoolean.true
      )
    end
    tc "$var * 3" do
      BinaryOperator.new(
        "*",
        Variable.new("var"),
        PioneInteger.new(3)
      )
    end
    tc "($Var1 == \"a\") && ($Var2 == \"b\")" do
      BinaryOperator.new(
        "&&",
        BinaryOperator.new(
          "==",
          Variable.new("Var1"),
          PioneString.new("a")
        ),
        BinaryOperator.new(
          "==",
          Variable.new("Var2"),
          PioneString.new("b")
        )
      )
    end
  end

  transformer_spec("message", :expr) do
    tc "1.next" do
      Message.new("next", PioneInteger.new(1))
    end
    tc "1.next.next" do
      Message.new(
        "next",
        Message.new("next", PioneInteger.new(1))
      )
    end
    tc "\"abc\".index(1,1)" do
      Message.new(
        "index",
        PioneString.new("abc"),
        PioneInteger.new(1),
        PioneInteger.new(1)
      )
    end
    tc "(1 + 2).prev" do
      Message.new(
        "prev",
        BinaryOperator.new(
          "+",
          PioneInteger.new(1),
          PioneInteger.new(2)
        )
      )
    end
    tc "abc.sync" do
      Message.new("sync", RuleExpr.new(Package.new("main"), "abc"))
    end
    tc "'*.txt'.all" do
      Message.new("all", DataExpr.new("*.txt"))
    end
    tc "'*.txt'.all()" do
      Message.new("all", DataExpr.new("*.txt"))
    end
    tc "'*.txt'.all(true)" do
      Message.new("all", DataExpr.new("*.txt"), PioneBoolean.true)
    end
  end

  transformer_spec("parameters", :expr) do
    tc "{}" do
      Parameters.new({})
    end
    tc "{var1: 1}" do
      {"var1" => 1}.to_params
    end
    tc "{var1: 1, var2: 2}" do
      {"var1" => 1, "var2" => 2}.to_params
    end
    tc "{var1: \"a\", var2: \"b\", var3: \"c\"}" do
      {"var1" => "a", "var2" => "b", "var3" => "c"}.to_params
    end
  end
end
