module Pione
  module Lang
    # DocumentParser is a parser for PIONE document.
    class DocumentParser < Parslet::Parser
      include Util::ParsletParserExtension
      include CommonParser
      include LiteralParser
      include ExprParser
      include ContextParser
      include ConditionalBranchParser
      include DeclarationParser

      #
      # root
      #
      root(:package_context)
    end
  end
end
