module Pione
  module Lang
    # DocumentTransformer is a transformer for PIONE document.
    class DocumentTransformer < Parslet::Transform
      include LiteralTransformer
      include ExprTransformer
      include ContextTransformer
      include ConditionalBranchTransformer
      include DeclarationTransformer
    end
  end
end
