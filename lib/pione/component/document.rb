module Pione
  module Component
    class Document < StructX
      class << self
        # Load a PIONE rule document as file.
        def load(src, opt)
          parse(src.read, opt)
        end

        # Parse a PIONE rule document as string.
        def parse(src, opt)
          # parse the document
          stree = Parser::DocumentParser.new.parse(src)

          # model transformation
          transformer = Transformer::DocumentTransformer.new
          return transformer.apply(stree, opt)
        end
      end
    end
  end
end
