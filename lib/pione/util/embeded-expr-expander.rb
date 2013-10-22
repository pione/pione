module Pione
  module Util
    module EmbededExprExpander
      # Expand embeded expressions in the string.
      def self.expand(env, str)
        return nil if str.nil?

        # parse and transform
        str.gsub(/\{(\$.+?)\}|\<\?\s*(.+?)\s*\?>/) do
          tree = Lang::DocumentParser.new.expr.parse($1 || $2)
          expr = Lang::DocumentTransformer.new.apply(tree, {package_name: nil, filename: nil})
          expr.eval(env).call_pione_method(env, "textize", []).value
        end
      end
    end
  end
end
