require 'pione/common'

module Pione
  class Transformer
    module Literal
      include TransformerModule

      # boolean
      rule(:boolean => simple(:s)) do
        (s == "true") ? Model::PioneBoolean.true : Model::PioneBoolean.false
      end

      # string
      rule(:string => simple(:s)) do
        Model::PioneString.new(s.str.gsub(/\\(.)/){$1})
      end

      # integer
      rule(:integer => simple(:i)) do
        Model::PioneInteger.new(i.to_i)
      end

      # float
      rule(:float => simple(:f)) do
        Model::PioneFloat.new(f.to_f)
      end

      # variable
      rule(:variable => simple(:v)) do
        Model::Variable.new(v)
      end

      # data_name
      # escape characters are substituted
      rule(:data_name => simple(:name)) do
        Model::DataExpr.new(name.str.gsub(/\\(.)/) {$1})
      end

      # package_name
      rule(:package_name => simple(:name)) do
        Model::Package.new(name)
      end

      # rule_name
      rule(:rule_name => simple(:name)) do
        Model::RuleExpr.new(name)
      end
    end
  end
end
