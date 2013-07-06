module Pione
  module Transformer
    # ExprTransformer is a transformer for syntax tree of expressions.
    module ExprTransformer
      include TransformerModule

      # Transform +expr_operator_application+ into +Model::Message+.
      rule(:expr_operator_application =>
           { :left => simple(:left),
             :operator => simple(:operator),
             :right => simple(:right) }) {
        Model::Message.new(operator.to_s, left, right)
      }

      # Extract the content of +:expr+.
      rule(:expr => simple(:obj)) { obj }

      # Transform receiver and messages as Model::Message.
      rule({ :receiver => simple(:receiver),
             :messages => sequence(:messages) }) {
        messages.inject(receiver) do |rec, msg|
          Model::Message.new(msg.name, rec, *msg.parameters)
        end
      }

      # Transform receiver and reverse message as Model::Message.
      rule({ :receiver => simple(:receiver),
             :reverse_messages => sequence(:messages) }) {
        messages.reverse.inject(receiver) do |obj, msg|
          Model::Message.new(msg.name, obj, *msg.parameters)
        end
      }

      # Transform receiver and indexes as Model::Message.
      rule({ :receiver => simple(:receiver),
             :indexes => sequence(:indexes) }) {
        indexes.inject(receiver) do |rec, msg|
          Model::Message.new("[]", rec, *msg.parameters)
        end
      }

      # Transform +:message+ with no parameters as OpenStruct.
      rule(:message => {:message_name => simple(:name)}) {
        OpenStruct.new(name: name)
      }

      # Transform +:message+ with no parameters as OpenStruct.
      rule(:message =>
        { :message_name => simple(:name),
          :message_parameters => nil }) {
        OpenStruct.new(name: name)
      }

      # Transform +:message+ with parameters as OpenStruct.
      rule(:message =>
        { :message_name => simple(:name),
          :message_parameters => sequence(:parameters) }) {
        OpenStruct.new(name: name, parameters: parameters)
      }

      # Transform +:message+ with parameters as OpenStruct.
      rule(:message =>
        { :message_name => simple(:name),
          :message_parameters => simple(:arg) }) {
        OpenStruct.new(name: name, parameters: arg)
      }

      # data null
      rule(:data_null => simple(:obj)) {
        Model::DataExprNull.instance.to_seq
      }

      # Extract the content of +:rule_expr+.
      rule(:rule_expr => simple(:rule)) { rule }

      # Extract the content of +:rule_expr+ and set the package.
      rule(:rule_expr => {
          :package => simple(:package),
          :expr => simple(:expr)
        }) {
        expr.set_package_expr(package)
      }

      # Transform +:parameters+ as emtpy parameters.
      rule(:parameters => nil) { Parameters.new({}) }

      # Transform +:parameters+ as emtpy parameters.
      rule(:parameters => simple(:elt)) {
        Parameters.new({elt.key => elt.value})
      }

      # Transform +:parameters+ as parameters.
      rule(:parameters => sequence(:list)) {
        elts = Hash[*list.map{|elt| [elt.key, elt.value]}.flatten(1)]
        Parameters.new(elts)
      }

      # Transform +:parameters_element+ as key and value pair.
      rule(:parameters_element => {
          :key => simple(:key),
          :value => simple(:value)
        }) {
        var = Variable.new(key.str).tap do |x|
          x.set_line_and_column(key.line_and_column)
        end
        OpenStruct.new(key: var, value: value)
      }

      # Transform +:index+ as name and parameters structure.
      rule(:index => sequence(:args)) {
        OpenStruct.new(name: "[]", parameters: args)
      }

      # Transform +:postpositional_parameters+ as parameters structure.
      rule(:postpositional_parameters => simple(:parameters)) {
        OpenStruct.new(name: "params", parameters: parameters)
      }
    end
  end
end
