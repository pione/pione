module Pione
  module Transformer
    MessageArgument = Struct.new(:name, :parameters)
    ParametersElement = Struct.new(:key, :value)

    module ExprTransformer
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
        messages.inject(receiver) do |obj, msg|
          Model::Message.new(msg.name, obj, *msg.parameters)
        end
      }

      # receiver with reverse message
      rule({ :receiver => simple(:receiver),
             :reverse_messages => sequence(:messages) }) {
        messages.reverse.inject(receiver) do |obj, msg|
          Model::Message.new(msg.name, obj, *msg.parameters)
        end
      }

      # message
      rule(:message => {:message_name => simple(:name)}) {
        MessageArgument.new(name)
      }
      rule(:message =>
           { :message_name => simple(:name),
             :message_parameters => nil }) {
        MessageArgument.new(name)
      }
      rule(:message =>
           { :message_name => simple(:name),
             :message_parameters => sequence(:parameters) }) {
        MessageArgument.new(name, parameters)
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

      rule(:postpositional_parameters => simple(:parameters)) {
        MessageArgument.new("params", parameters)
      }
    end
  end
end
