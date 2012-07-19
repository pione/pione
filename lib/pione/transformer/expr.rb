require 'pione/common'

module Pione
  class Transformer
    class MessageArgument < Struct.new(:name, :parameters); end

    module Expr
      include TransformerModule

      # expr_operator_application
      rule(:expr_operator_application =>
           { :left => simple(:left),
             :operator => simple(:operator),
             :right => simple(:right) }) {
        Model::BinaryOperator.new(operator, left, right)
      }

      # expr
      rule(:expr => simple(:obj)) { obj }
      rule(:expr =>
           { :receiver => simple(:receiver),
             :messages => sequence(:messages) }) {
        obj = receiver
        messages.each do |msg|
          obj = Model::Message.new(msg.name, obj, *msg.parameters)
        end
        obj
      }

      # message
      rule(:message => {:message_name => simple(:name)}) {
        MessageArgument.new(name)
      }
      rule(:message =>
           { :message_name => simple(:name),
             :message_parameters => sequence(:parameters) }) {
        MessageArgument.new(name, parameters)
      }
      rule(:message =>
           { :message_name => simple(:name),
             :message_parameters => nil }) {
        MessageArgument.new(name)
      }
      rule(:message =>
           { :message_name => simple(:name),
             :message_parameters => simple(:arg) }) {
        MessageArgument.new(name, arg)
      }

      # rule_expr
      rule(:rule_expr => simple(:rule)) { rule }
      rule(:rule_expr =>
           { :package => simple(:package),
             :expr => simple(:expr) }) {
        expr.set_package(package)
      }
    end
  end
end
