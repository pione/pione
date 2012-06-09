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

      # feature_name
      # convert into plain string
      rule(:feature_name =>
           { :feature_mark => simple(:mark),
             :identifier => simple(:name)}
           ) do
        case mark
        when "+"
          FeatureRequisite.new(name.str)
        when "-"
          FeatureExclusive.new(name.str)
        when "?"
          FeaturePreferred.new(name.str)
        end
      end

      # string
      rule(:string => simple(:s)) { s.str.gsub(/\\(.)/) {$1} }

      # integer
      rule(:integer => simple(:i)) { i.to_i }

      # float
      rule(:float => simple(:f)) { f.to_f }

    end
  end
end
