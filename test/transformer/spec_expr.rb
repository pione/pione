require 'pione/test-util'

def execute_testcase(msg, testcase)
  testcase.each do |string, val|
    it "#{msg}: #{string}" do
      res = Transformer.new.apply(Parser.new.expr.parse(string))
      res.should == val
    end
  end
end

describe 'Transformer::Expr' do
  describe 'binary operator' do
    testcase_binary_operator = {
      "1 + 2" =>
      Model::BinaryOperator.new("+",
                                PioneInteger.new(1),
                                PioneInteger.new(2)),
      '"a" + "b"' =>
      Model::BinaryOperator.new("+",
                                PioneString.new("a"),
                                PioneString.new("b")),
      "false || true" =>
      Model::BinaryOperator.new("||",
                                PioneBoolean.false,
                                PioneBoolean.true),
      "$var * 3" =>
      Model::BinaryOperator.new("*",
                                Variable.new("var"),
                                PioneInteger.new(3)),
      "($Var1 == \"a\") && ($Var2 == \"b\")" =>
      Model::BinaryOperator.new("&&",
                                Model::BinaryOperator.new("==",
                                                          Model::Variable.new("Var1"),
                                                          Model::PioneString.new("a")),
                                Model::BinaryOperator.new("==",
                                                          Model::Variable.new("Var2"),
                                                          Model::PioneString.new("b"))),
    }
    execute_testcase("should get binary operator", testcase_binary_operator)

    testcase_message = {
      "1.next" =>
      Model::Message.new("next",
                         Model::PioneInteger.new(1)),
      "1.next.next" =>
      Model::Message.new("next",
                         Model::Message.new("next",
                                            Model::PioneInteger.new(1))),
      "\"abc\".index(1,1)" =>
      Model::Message.new("index",
                         Model::PioneString.new("abc"),
                         Model::PioneInteger.new(1),
                         Model::PioneInteger.new(1)),
      "(1 + 2).prev" =>
      Model::Message.new("prev",
                         Model::BinaryOperator.new("+",
                                                   Model::PioneInteger.new(1),
                                                   Model::PioneInteger.new(2))),
      "abc.sync" =>
      Model::Message.new("sync",
                         Model::RuleExpr.new("abc"))
    }
    execute_testcase("should get message", testcase_message)
  end
end
