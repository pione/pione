module Pione
  module Transformer
    # LiteralTransformer is a transformer for syntax tree of literals.
    module LiteralTransformer
      include TransformerModule

      # Tranform +boolean+ into Model::BooleanSequence.
      rule(:boolean => simple(:b)) do
        Model::BooleanSequence.of(b == "true") do |expr|
          line, col = b.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +string+ into Model::StringSequence.
      rule(:string => subtree(:tree)) do
        # empty string if content is an empty list
        content = tree[:content] == [] ? "" : tree[:content]
        # make string sequence
        Model::StringSequence.of(Util::BackslashNotation.apply(content)).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +integer+ as Model::IntegerSequence.
      rule(:integer => simple(:i)) do
        Model::IntegerSequence.of(i.to_i).tap do |expr|
          line, col = i.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +float+ as Model::FloatSequence.
      rule(:float => simple(:f)) do
        Model::FloatSequence.of(f.to_f).tap do |expr|
          line, col = f.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +variable+ as Model::VariableSequence.
      rule(:variable => subtree(:tree)) {
        Model::Variable.new(tree[:name].str).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +data_expr+ as Model::DataExprSequence.
      rule(:data_expr => subtree(:tree)) {
        if tree[:null]
          val = Model::DataExprNull.new
        else
          val = Model::DataExpr.new(Util::BackslashNotation.apply(tree[:pattern].str))
        end

        Model::DataExprSequence.of(val).tap do |expr|
          line, col = (tree[:header] || tree[:null]).line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +:package_expr+ into Model::PackageExprSequence.
      rule(:package_expr => subtree(:tree)) {
        PackageExprSequence.of(tree[:identifier].str).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +rule_expr+ into Model::RuleExprSequence.
      rule(:rule_expr => simple(:name)) do
        Model::RuleExprSequence.of(name.str).tap do |expr|
          line, col = name.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +ticket_expr+ into TicketExprSequence.
      rule(:ticket_expr => subtree(:tree)) {
        Model::TicketExprSequence.of(tree[:name].str).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +:parameters+ as Model::Paramters.
      rule(:parameter_set => subtree(:tree)) {
        elts = tree[:elements]
        case elts
        when nil
          Model::ParameterSetSequence.new
        when Array
          Model::ParameterSetSequence.of(Hash[*elts.map{|e| [e.key, e.value]}.flatten(1)])
        else
          Model::ParameterSetSequence.of({elts.key => elts.value})
        end.tap do |params|
          line, col = tree[:header].line_and_column
          params.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +:parameters_element+ as key and value pair.
      rule(:parameter_set_element => subtree(:tree)) {
        OpenStruct.new(key: tree[:key].str, value: tree[:value])
      }

      # Transform +feature+ into FeatureSequence.
      rule(:feature => simple(:piece)) do
        Model::FeatureSequence.of(piece)
      end

      # Transform +requisite_feature+ into RequisiteFeature.
      rule(:requisite_feature => subtree(:tree)) do
        Model::RequisiteFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +blocking_feature+ into BlockingFeature.
      rule(:blocking_feature => subtree(:tree)) do
        Model::BlockingFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +preferred_feature+ into PreferredFeature.
      rule(:preferred_feature => subtree(:tree)) do
        Model::PreferredFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +possible_feature+ into PossibleFeature.
      rule(:possible_feature => subtree(:tree)) do
        Model::PossibleFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +restrictive_feature+ into RestrictiveFeature.
      rule(:restrictive_feature => subtree(:tree)) do
        Model::RestrictiveFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +empty_feature+ into EmptyFeature.
      rule(:empty_feature => subtree(:tree)) do
        Model::EmptyFeature.new.tap do |feature|
          line, col = tree[:symbol].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +almighty_feature+ into AlmightyFeature.
      rule(:almighty_feature => subtree(:tree)) do
        Model::AlmightyFeature.new.tap do |feature|
          line, col = tree[:symbol].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end
    end
  end
end
