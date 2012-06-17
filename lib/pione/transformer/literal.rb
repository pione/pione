require 'pione/common'

module Pione
  class Transformer
    module Literal
      include TransformerModule

      # data_name
      # escape characters are substituted
      rule(:data_name => simple(:name)) do
        name.str.gsub(/\\(.)/) {$1}
      end

      # boolean
      rule(:boolean => simple(:s)) do
        s == "true" ? Model::PioneBoolean.true : Model::PioneBoolean.false
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
    end
  end
end
