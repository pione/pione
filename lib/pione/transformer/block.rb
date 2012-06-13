module Pione
  class Transformer
    module Block
      include TransformerModule

      rule(:flow_block => sequence(:elements) {
        return elements
      }
    end
  end
end
