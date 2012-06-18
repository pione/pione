require 'pione/common'

module Pione
  class Transformer
    module Expr
      include TransformerModule

      rule(:expr_operator_application =>
           { :left => simple(:left),
             :operator => simple(:operator),
             :right => simple(:right) }) do
        Model::BinaryOperator.new(operator, left, right)
      end

      rule(:)
    end
  end
end
