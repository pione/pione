require 'innocent-white/common'

module InnocentWhite
  class Transformer
    module Literal
      include TransformerModule

      # data_name
      # escape characters are substituted
      rule(:data_name => simple(:name)) {
        name.str.gsub(/\\(.)/) {$1}
      }

      # feature_name
      # convert into plain string
      rule(:feature_name =>
           { :feature_mark => simple(:mark),
             :identifier => simple(:name)}
           ) {
        type = case mark
               when "+"
                 :requisite
               when "-"
                 :exclusive
               when "?"
                 :preferred
               end
        FeatureExpr.new(name.str, type)
      }

      # string
      rule(:string => simple(:s)) { s.str.gsub(/\\(.)/) {$1} }

      # integer
      rule(:integer => simple(:i)) { i.to_i }

      # float
      rule(:float => simple(:f)) { f.to_f }

    end
  end
end
