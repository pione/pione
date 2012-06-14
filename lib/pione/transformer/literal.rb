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

      # string
      rule(:string => simple(:s)) { s.str.gsub(/\\(.)/) {$1} }

      # integer
      rule(:integer => simple(:i)) { i.to_i }

      # float
      rule(:float => simple(:f)) { f.to_f }

      # variable
      rule(:variable => simple(:v)) do
        Variable.new(v)
      end
    end
  end
end
