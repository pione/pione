module Pione
  module Transformer
    # ExprTransformer is a transformer for syntax tree of expressions.
    module ExprTransformer
      include TransformerModule

      # Transform +expr_operator_application+ into +Lang::Message+.
      rule(:expr_operator_application =>
           { :left => simple(:left),
             :operator => simple(:operator),
             :right => simple(:right) }) {
        Lang::Message.new(operator.to_s, left, [right]).tap do |msg|
          line, col = left.line_and_column
          msg.set_source_position(package_name, filename, line, col)
        end
      }

      # Extract the content of +:expr+.
      rule(:expr => simple(:obj)) { obj }

      # Transform receiver and messages as Lang::Message.
      rule({ :receiver => simple(:receiver),
             :messages => sequence(:messages) }) {
        messages.inject(receiver) do |rec, msg|
          Lang::Message.new(msg.name.to_s, rec, msg.parameters).tap do |x|
            line, col = receiver.line_and_column
            x.set_source_position(package_name, filename, line, col)
          end
        end
      }

      # Transform receiver and reverse message as Lang::Message.
      rule({ :receiver => simple(:receiver),
             :reverse_messages => sequence(:messages) }) {
        messages.reverse.inject(receiver) do |obj, msg|
          Lang::Message.new(msg.name.to_s, obj, msg.parameters).tap do |x|
            line, col = msg.line_and_column
            x.set_source_position(package_name, filename, line, col)
          end
        end
      }

      # Transform receiver and indexes as Lang::Message.
      rule({ :receiver => simple(:receiver),
             :indexes => sequence(:indexes) }) {
        indexes.inject(receiver) do |rec, msg|
          Lang::Message.new("[]", rec, msg.parameters).tap do |x|
            line, col = msg.line_and_column
            x.set_source_position(package_name, filename, line, col)
          end
        end
      }

      # Transform +:message+ with no parameters as OpenStruct.
      rule(:message => {:message_name => simple(:name)}) {
        OpenStruct.new(name: name, parameters: [])
      }

      # Transform +:message+ with no parameters as OpenStruct.
      rule(:message =>
        { :message_name => simple(:name),
          :message_parameters => nil }) {
        OpenStruct.new(name: name, parameters: [])
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
        OpenStruct.new(name: name, parameters: [arg])
      }

      # data null
      rule(:data_null => simple(:obj)) {
        Lang::DataExprSequence.of(Lang::DataExprNull.instance)
      }


      # Extract the content of +rule_expr+.
      rule(:rule_expr => simple(:rule)) { rule }

      # Extract the content of +rule_expr+ and set the package.
      rule(:rule_expr => {
          :package => simple(:package),
          :expr => simple(:expr)
        }) {
        expr.set_package_expr(package)
      }

      # Transform +:index+ as name and parameters structure.
      rule(:index => sequence(:args)) {
        OpenStruct.new(name: "[]", parameters: args)
      }

      # Transform +postpositional_parameter_set+ as parameters structure.
      rule(:postpositional_parameter_set => simple(:parameter_set)) {
        OpenStruct.new(name: "param", parameters: [parameter_set])
      }
    end
  end
end
