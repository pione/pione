module Pione
  module Util
    module Misc
      # Ignores all exceptions of the block execution.
      # @yield []
      #   target block
      # @return [void]
      def ignore_exception(*exceptions, &b)
        exceptions = [Exception] if exceptions.empty?
        b.call
      rescue *exceptions => e
        Log::Debug.ignored_exception(e)
        return false
      end

      def error?(option={}, &b)
        sec = option[:timeout]
        begin
          timeout(sec) do
            b.call
            false
          end
        rescue Object => e
          true
        end
      end

      # Returns the hostname of the machine.
      # @return [String]
      #   hostname
      def hostname
        Socket.gethostname
      end

      def parse_features(textual_features)
        stree = Parser::DocumentParser.new.expr.parse(textual_features)
        opt = {package_name: "*feature*", filename: "*feature*"}
        Transformer::DocumentTransformer.new.apply(stree, opt)
      end
    end

    extend Misc
  end
end
