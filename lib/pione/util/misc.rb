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
        stree = Lang::DocumentParser.new.expr.parse(textual_features)
        opt = {package_name: "*Feature*", filename: "*Feature*"}
        Lang::DocumentTransformer.new.apply(stree, opt)
      end

      def parse_param_set(textual_param_set)
        stree = Lang::DocumentParser.new.parameter_set.parse(textual_param_set)
        opt = {package_name: "*ParamSet*", filename: "*ParamSet*"}
        params = Lang::DocumentTransformer.new.apply(stree, opt)
      end
    end

    extend Misc
  end
end
