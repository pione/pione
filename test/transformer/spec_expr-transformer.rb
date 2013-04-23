require_relative '../test-util'

describe 'Pione::Transformer::ExprTransformer' do
  transformer_spec("binary operator", :expr) do
    tc "1 + 2" do
      BinaryOperator.new("+", 1.to_pione, 2.to_pione)
    end

    tc '"a" + "b"' do
      BinaryOperator.new("+", "a".to_pione, "b".to_pione)
    end

    tc "false || true" do
      BinaryOperator.new("||", PioneBoolean.false, PioneBoolean.true)
    end

    tc "$Var * 3" do
      BinaryOperator.new("*", Variable.new("Var"), 3.to_pione)
    end

    tc "($Var1 == \"a\") && ($Var2 == \"b\")" do
      left = BinaryOperator.new("==", Variable.new("Var1"), "a".to_pione)
      right = BinaryOperator.new("==", Variable.new("Var2"), PioneString.new("b"))
      BinaryOperator.new("&&", left, right)
    end
  end

  transformer_spec("data_expr", :expr) do
    tc "'test.a'" do
      DataExpr.new("test.a")
    end

    tc "null" do
      DataExprNull.instance
    end
  end

  transformer_spec("message", :expr) do
    tc "1.next" do
      Message.new("next", 1.to_pione)
    end

    tc "1.next.next" do
      Message.new("next", Message.new("next", 1.to_pione))
    end

    tc "\"abc\".index(1,1)" do
      Message.new("index", "abc".to_pione, 1.to_pione, 1.to_pione)
    end

    tc "(1 + 2).prev" do
      Message.new("prev", BinaryOperator.new("+", 1.to_pione, 2.to_pione))
    end

    tc "abc.sync" do
      rule = RuleExpr.new(Package.new("main"), "abc", Parameters.empty, TicketExpr.empty, TicketExpr.empty)
      Message.new("sync", rule)
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
