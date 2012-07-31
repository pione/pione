require 'pione/common'

module Pione
  class Transformer
    module Literal
      include TransformerModule

      # boolean
      rule(:boolean => simple(:s)) do
        line_and_column = s.line_and_column
        val = (s == "true")
        Model::PioneBoolean.new(val) do
          set_line_and_column(line_and_column)
        end
      end

      # string
      rule(:string => simple(:s)) do
        line_and_column = s.line_and_column
        Model::PioneString.new(s.str.gsub(/\\(.)/){$1}) do
          set_line_and_column(line_and_column)
        end
      end

      # integer
      rule(:integer => simple(:i)) do
        line_and_column = i.line_and_column
        Model::PioneInteger.new(i.to_i) do
          set_line_and_column(line_and_column)
        end
      end

      # float
      rule(:float => simple(:f)) do
        line_and_column = f.line_and_column
        Model::PioneFloat.new(f.to_f) do
          set_line_and_column(line_and_column)
        end
      end

      # variable
      rule(:variable => simple(:v)) do
        line_and_column = v.line_and_column
        Model::Variable.new(v) do
          set_line_and_column(line_and_column)
        end
      end

      # data_name
      # escape characters are substituted
      rule(:data_name => simple(:name)) do
        line_and_column = name.line_and_column
        Model::DataExpr.new(name.str.gsub(/\\(.)/) {$1}) do
          set_line_and_column(line_and_column)
        end
      end

      # package_name
      rule(:package_name => simple(:name)) do
        line_and_column = name.line_and_column
        Model::Package.new(name) do
          set_line_and_column(line_and_column)
        end
      end

      # rule_name
      rule(:rule_name => simple(:name)) do
        line_and_column = name.line_and_column
        RuleExpr.new(
          Package.new(Thread.current[:current_package_name]),
          name
        ) do
          set_line_and_column(line_and_column)
        end
      end
    end
  end
end
