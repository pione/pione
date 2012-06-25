class Pione::Transformer
  module RuleDefinition
    include Pione::TransformerModule

    # rule_definition
    rule(:rule_definition => {
           :rule_header => simple(:header),
           :rule_conditions => sequence(:conditions),
           :block => simple(:block) }) {
      name = header.name
      inputs = conditions.fileter{|c| c.type == :input}.map{|c| c.obj}
      outputs = conditions.fileter{|c| c.type == :output}.map{|c| c.obj}
      params = conditions.fileter{|c| c.type == :param}.map{|c| c.obj}
      features = conditions.fileter{|c| c.type == :feature}.map{|c| c.obj}
      block.concrete_class.new(name, inputs, outputs, params, features, block)
    }

    RuleCondition = Struct.new(:type, :obj)

    # input_line
    rule(:input_line => simple(:data_expr)) {
      check_data_type(data_expr, Model::TypeDataExpr)
      RuleCondition.new(:input, data_expr)
    }

    # output_line
    rule(:output_line => simple(:data_expr)) {
      check_model_type(data_expr, Model::TypeDataExpr)
      RuleCondition.new(:output, data_expr)
    }

    # param_line
    rule(:param_line => simple(:variable)) {
      check_data_type(variable, Model::TypeVariable)
      RuleCondition.new(:param, variable)
    }

    # feature_line
    rule(:feature_line => simple(:feature_expr)) {
      check_model_type(feature_expr, Model::TypeFeatureExpr)
      RuleCondition.new(:feature, feature_expr)
    }
  end
end
