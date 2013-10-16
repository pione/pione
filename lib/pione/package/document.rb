module Pione
  module Package
    # Package::Document provides functions that read PIONE document.
    class Document
      class << self
        # Load a PIONE rule document into the environment.
        def load(env, src, package_name, edition, tag, filename)
          _src = src.kind_of?(Location::DataLocation) ? src.read : src
          parse(_src, package_name, edition, tag, filename).eval(env)
        end

        # Parse a PIONE rule document as a string and return the package
        # context.
        def parse(src, package_name, edition, tag, filename)
          # make transformer options
          opt = {package_name: package_name, edition: edition, tag: tag, filename: filename}

          # parse the document
          stree = Lang::DocumentParser.new.parse(src)

          # model transformation
          return Lang::DocumentTransformer.new.apply(stree, opt)
        end
      end
    end
  end
end
