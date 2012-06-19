require 'pione/common'

module Pione
  class Transformer
    module Expr
      include TransformerModule

      rule(:expr_operator_application =>
           { :left => simple(:left),
             :operator => simple(:operator),
             :right => simple(:right) }) {
        Model::BinaryOperator.new(operator, left, right)
      }

      rule(:expr =>
           { :atom => simple(:atom),
             :messages => sequence(:messages) }) {
        if messages.empty?
          atom
        else
          obj = atom
          messages.each do |msg|
            obj = Model::Message.new(msg, obj, msg.params)
          end
          obj
        end
      }

      rule(:atomic_expr =>
           { :atom => simple(:atom),
             :messages => sequence(:messages) }) {
        if messages.empty?
          atom
        else
          obj = atom
          messages.each do |msg|
            obj = Model::Message.new(msg, obj, msg.params)
          end
          obj
        end
      }
    end
  end
end
