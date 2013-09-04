module Pione
  module Transformer
    # InterpolatorTransformer is a transformer for PIONE embeded expressions.
    class InterpolatorTransformer < Parslet::Transform
      include LiteralTransformer
      include ExprTransformer

      rule(:interpolators => sequence(:list)) { list }
      rule(:embeded_expr => simple(:expr)) { expr }
      rule(:narrative => simple(:str)) { str.to_s }
    end
  end
end
