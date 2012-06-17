require 'pione/test-util'

describe 'Transformer::Expr' do
  describe 'binary operator' do
    data = {
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
                                PioneInteger.new(3))
    }
    data.each do |string, val|
      it "should get binary operator: #{string}" do
        res = Transformer.new.apply(Parser.new.expr.parse(string))
        res.should == val
      end
    end
  end
end
