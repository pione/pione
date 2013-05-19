module Pione
  module Transformer
    # LiteralTransformer is a transformer for syntax tree of literals.
    module LiteralTransformer
      include TransformerModule

      # Tranform +:boolean+ as Model::PioneBoolean.
      rule(:boolean => simple(:s)) do
        val = (s == "true")
        Model::PioneBoolean.new(val).tap do |x|
          x.set_line_and_column(s.line_and_column)
          break Model::BooleanSequence.new([x])
        end
      end

      # Transform +:string+ as Model::PioneString.
      rule(:string => simple(:s)) do
        # convert backslash notations
        val = s.str.gsub(/\\(.)/){$1}
        Model::PioneString.new(val).tap do |x|
          x.set_line_and_column(s.line_and_column)
          break Model::StringSequence.new([x])
        end
      end

      # NOTE: how do we get the position of empty string?
      rule(:string => sequence(:empty)) do
        # convert backslash notations
        Model::StringSequence.new([Model::PioneString.new("")])
      end

      # Transform +:integer+ as Model::PioneInteger.
      rule(:integer => simple(:i)) do
        Model::PioneInteger.new(i.to_i).tap do |x|
          x.set_line_and_column(i.line_and_column)
          break Model::IntegerSequence.new([x])
        end
      end

      # Transform +:float+ as Model::PioneFloat.
      rule(:float => simple(:f)) do
        Model::PioneFloat.new(f.to_f).tap do |x|
          x.set_line_and_column(f.line_and_column)
          break Model::FloatSequence.new([x])
        end
      end

      # Transform +:variable+ as Model::Variable.
      rule(:variable => simple(:var)) do
        Model::Variable.new(var.str).tap do |x|
          x.set_line_and_column(var.line_and_column)
        end
      end

      # Transform +:data_name+ as Model::DataExpr.
      rule(:data_name => simple(:name)) do
        # convert backslash notations
        val = name.str.gsub(/\\(.)/){$1}
        Model::DataExpr.new(val).tap do |x|
          x.set_line_and_column(name.line_and_column)
          break Model::DataExprSequence.new([x])
        end
      end

      # Transform +:package_name+ as Model::PackageExpr.
      rule(:package_name => simple(:name)) do
        val = name.str
        Model::PackageExpr.new(val).tap do |x|
          x.set_line_and_column(name.line_and_column)
        end
      end

      # Transform +:rule_name+ as Model::RuleExpr.
      rule(:rule_name => simple(:name)) do
        package = PackageExpr.new(Thread.current[:current_package_name])
        val = name.str
        RuleExpr.new(package, val).tap do |x|
          x.set_line_and_column(name.line_and_column)
        end
      end

      # ticket
      rule(:ticket => simple(:name)) do
        line_and_column = name.line_and_column
        TicketExpr.new(name.to_s) do
          set_line_and_column(line_and_column)
        end.to_seq
      end
    end
  end
end
