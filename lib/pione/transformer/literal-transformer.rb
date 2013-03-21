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
        end
      end

      # Transform +:string+ as Model::PioneString.
      rule(:string => simple(:s)) do
        # convert backslash notations
        val = s.str.gsub(/\\(.)/){$1}
        Model::PioneString.new(val).tap do |x|
          x.set_line_and_column(s.line_and_column)
        end
      end

      # Transform +:integer+ as Model::PioneInteger.
      rule(:integer => simple(:i)) do
        Model::PioneInteger.new(i.to_i).tap do |x|
          x.set_line_and_column(i.line_and_column)
        end
      end

      # Transform +:float+ as Model::PioneFloat.
      rule(:float => simple(:f)) do
        Model::PioneFloat.new(f.to_f).tap do |x|
          x.set_line_and_column(f.line_and_column)
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
        end
      end

      # Transform +:package_name+ as Model::Package.
      rule(:package_name => simple(:name)) do
        val = name.str
        Model::Package.new(val).tap do |x|
          x.set_line_and_column(name.line_and_column)
        end
      end

      # Transform +:rule_name+ as Model::RuleExpr.
      rule(:rule_name => simple(:name)) do
        package = Package.new(Thread.current[:current_package_name])
        val = name.str
        RuleExpr.new(package, val).tap do |x|
          x.set_line_and_column(name.line_and_column)
        end
      end
    end
  end
end
