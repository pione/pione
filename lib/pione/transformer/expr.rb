module Pione
  module Transformer
    MessageArgument = Struct.new(:name, :parameters)
    ParametersElement = Struct.new(:key, :value)

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

      # receiver
      rule({ :receiver => simple(:receiver),
             :messages => sequence(:messages) }) {
        obj = receiver
        messages.each do |msg|
          obj = Model::Message.new(msg.name, obj, *msg.parameters)
        end
        obj
      }
      rule({ :receiver => simple(:receiver),
             :indexes => sequence(:indexes) }) {
        obj = receiver
        indexes.each do |msg|
          obj = Model::Message.new("[]", obj, *msg.parameters)
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
      rule(:rule_expr => {
          :package => simple(:package),
          :expr => simple(:expr)
        }) {
        expr.set_package(package)
      }

      # parameters
      rule(:parameters => nil) { Parameters.new({}) }
      rule(:parameters => simple(:elt)) {
        Parameters.new({elt.key => elt.value})
      }
      rule(:parameters => sequence(:list)) {
        elts = Hash[*list.map{|elt| [elt.key, elt.value]}.flatten(1)]
        Parameters.new(elts)
      }

      rule(:parameters_element => {
          :key => simple(:key),
          :value => simple(:value)
        }) {
        ParametersElement.new(Variable.new(key.to_s), value)
      }

      rule(:index => sequence(:args)) {
        MessageArgument.new("[]", args)
      }
    end
  end
end
