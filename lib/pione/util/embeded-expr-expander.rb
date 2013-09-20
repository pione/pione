module Pione
  module Util
    module EmbededExprExpander
      # Expand embeded expressions in the string.
      def self.expand(env, str)
        # parse and transform
        tree = Lang::InterpolatorParser.new.parse(str)
        list = Lang::InterpolatorTransformer.new.apply(tree, {package_name: nil, filename: nil})

        # evaluate and join
        list.map do |elt|
          if elt.is_a?(String)
            elt
          else
            elt.eval(env).call_pione_method(env, "textize", []).value
          end
        end.join("")
      end
    end
  end
end
