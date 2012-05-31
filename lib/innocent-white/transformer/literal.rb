require 'innocent-white/common'

module InnocentWhite
  class Transformer
    module Literal
      include Parslet

      p methods.sort

      # data_name
      # escape characters are substituted
      rule(:data_name => simple(:name)) {
        name.str.gsub(/\\(.)/) {$1}
      }

      # feature_name
      # convert into plain string
      rule(:feature_name => simple(:name)) {
        name.str
      }

      # string
      rule(:string => simple(:s)) { s.str }

      # integer
      rule(:integer => simple(:i)) { i.to_i }

      # float
      rule(:float => simple(:f)) { f.to_f }

    end
  end
end
