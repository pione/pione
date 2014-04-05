module Pione
  module Util
    # Evaluatable is a module for providing to ability to evaluate PIONE
    # expression string.
    module Evaluatable
      # Evaluate the string as a PIONE expression and get the result value as model object.
      #
      # @param str [String]
      #   a PIONE expression
      # @param domain_dump [DomainDump]
      #   a domain dump object
      # @return [Object]
      #   the evaluation value
      def val!(str, domain_dump=nil)
        env = domain_dump ? domain_dump.env : Lang::Environment.new
        option = {package_name: env.current_package_id, filename: "pione-eval"}
        Lang::DocumentTransformer.new.apply(
          Lang::DocumentParser.new.expr.parse(str), option
        ).eval(env)
      end

      # Evaluate the string as a PIONE expression and get the result value as a textized string.
      #
      # @param str [String]
      #   a PIONE expression
      # @param domain_dump [DomainDump]
      #   a domain dump object
      # @return [String]
      #   the result of evaluation as an embeddable string
      def val(str, domain_dump=nil)
        env = domain_dump ? domain_dump.env : Lang::Environment.new
        val!(str, domain_dump).call_pione_method(env, "textize", []).first.value
      end
    end
  end
end
