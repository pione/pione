class Pione::Transformer
  module RuleDefinition
    include Pione::TransformerModule

    # rule_definition
    rule(:rule_definition => subtree(:tree)) {
      name = tree[:rule_header].name
      inputs = tree[:inputs]
      outputs = tree[:outputs]
      params = tree[:params]
      features = tree[:features]
      block = tree[:block]
      block.concrete_class.new(name, inputs, outputs, params, features, block)
    }

    # input_line
    rule(:input_line => simple(:data_expr)) {
      check_data_type(data_expr, Model::TypeDataExpr)
      if input[:input_header] == "input-all"
        data_expr.all
      else
        data_expr
      end
    }

    # output_line
    rule(:output_line => simple(:data_expr)) {
      check_model_type(data_expr, Model::TypeDataExpr)
      if output[:output_header] == "output-all"
        data_expr.all
      else
        data_expr
      end
    }

    # param_line
    rule(:param_line => simple(:variable)) {
      check_data_type(variable, :variable)
    }

    # feature_line
    rule(:feature_line => simple(:feature_expr)) {
      check_model_type(feature_expr, :feature_expr)
    }
  end
end
