module Pione
  module Transformer
    # LiteralTransformer is a transformer for syntax tree of literals.
    module LiteralTransformer
      include TransformerModule

      # Tranform +boolean+ into Lang::BooleanSequence.
      rule(:boolean => simple(:b)) do
        Lang::BooleanSequence.of(b == "true") do |expr|
          line, col = b.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +string+ into Lang::StringSequence.
      rule(:string => subtree(:tree)) do
        # empty string if content is an empty list
        content = tree[:content] == [] ? "" : tree[:content]
        # make string sequence
        Lang::StringSequence.of(Util::BackslashNotation.apply(content)).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +integer+ as Lang::IntegerSequence.
      rule(:integer => simple(:i)) do
        Lang::IntegerSequence.of(i.to_i).tap do |expr|
          line, col = i.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +float+ as Lang::FloatSequence.
      rule(:float => simple(:f)) do
        Lang::FloatSequence.of(f.to_f).tap do |expr|
          line, col = f.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +variable+ as Lang::VariableSequence.
      rule(:variable => subtree(:tree)) {
        Lang::Variable.new(tree[:name].str).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +data_expr+ as Lang::DataExprSequence.
      rule(:data_expr => subtree(:tree)) {
        if tree[:null]
          val = Lang::DataExprNull.new
        else
          val = Lang::DataExpr.new(Util::BackslashNotation.apply(tree[:pattern].str))
        end

        Lang::DataExprSequence.of(val).tap do |expr|
          line, col = (tree[:header] || tree[:null]).line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +:package_expr+ into Lang::PackageExprSequence.
      rule(:package_expr => subtree(:tree)) {
        Lang::PackageExprSequence.of(tree[:identifier].str).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +rule_expr+ into Lang::RuleExprSequence.
      rule(:rule_expr => simple(:name)) do
        Lang::RuleExprSequence.of(name.str).tap do |expr|
          line, col = name.line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +ticket_expr+ into TicketExprSequence.
      rule(:ticket_expr => subtree(:tree)) {
        Lang::TicketExprSequence.of(tree[:name].str).tap do |expr|
          line, col = tree[:header].line_and_column
          expr.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +:parameters+ as Lang::Paramters.
      rule(:parameter_set => subtree(:tree)) {
        elts = tree[:elements]
        case elts
        when nil
          Lang::ParameterSetSequence.new
        when Array
          Lang::ParameterSetSequence.of(Hash[*elts.map{|e| [e.key, e.value]}.flatten(1)])
        else
          Lang::ParameterSetSequence.of({elts.key => elts.value})
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
        Lang::FeatureSequence.of(piece)
      end

      # Transform +requisite_feature+ into RequisiteFeature.
      rule(:requisite_feature => subtree(:tree)) do
        Lang::RequisiteFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +blocking_feature+ into BlockingFeature.
      rule(:blocking_feature => subtree(:tree)) do
        Lang::BlockingFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +preferred_feature+ into PreferredFeature.
      rule(:preferred_feature => subtree(:tree)) do
        Lang::PreferredFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +possible_feature+ into PossibleFeature.
      rule(:possible_feature => subtree(:tree)) do
        Lang::PossibleFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +restrictive_feature+ into RestrictiveFeature.
      rule(:restrictive_feature => subtree(:tree)) do
        Lang::RestrictiveFeature.new(tree[:name].str).tap do |feature|
          line, col = tree[:prefix].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +empty_feature+ into EmptyFeature.
      rule(:empty_feature => subtree(:tree)) do
        Lang::EmptyFeature.new.tap do |feature|
          line, col = tree[:symbol].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end

      # Transform +almighty_feature+ into AlmightyFeature.
      rule(:almighty_feature => subtree(:tree)) do
        Lang::AlmightyFeature.new.tap do |feature|
          line, col = tree[:symbol].line_and_column
          feature.set_source_position(package_name, filename, line, col)
        end
      end
    end
  end
end
