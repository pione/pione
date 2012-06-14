require 'pione/common'

module Pione
  class Transformer
    module Expr
      include TransformerModule

      rule(:expr_operator_application =>
           { :left => simple(:left),
             :operator => simple(:operator),
             :right => simple(:right) }) do
        Pione::Expr::BinaryOperator.make(operator, left, right)
      end
    end
  end
end
