module Pione
  module Util
    # Evaluatable is a module for providing to ability to evaluate PIONE
    # expression string.
    module Evaluatable
      # Evaluate the string as a PIONE expression and get the result value as model object.
      #
      # @param str [String]
      #   a PIONE expression string
      # @param domain_info [DomainInfo]
      #   domain info
      # @return [BasicModel]
      #   the result of evaluation
      def val!(str, domain_info=nil)
        domain_info = load_domain_info unless domain_info
        env = domain_info.env
        option = {package_name: env.current_package_id, filename: "pione-eval"}
        Transformer::DocumentTransformer.new.apply(
          Parser::DocumentParser.new.expr.parse(str), option
        ).eval(env)
      end

      # Evaluate the string as a PIONE expression and get the result value as a textized string.
      #
      # @param str [String]
      #   a PIONE expression string
      # @param domain_info [DomainInfo]
      #   domain info
      # @return [String]
      #   the result of evaluation as an embeddable string
      def val(str, domain_info=nil)
        domain_info = load_domain_info unless domain_info
        env = domain_info.env
        val!(str, domain_info).call_pione_method(env, "textize", []).first.value
      end

      private

      # Load default domain info file.
      def load_domain_info
        location = Location["./.domain.dump"]
        if location.exist?
          System::DomainInfo.read(location)
        else
          System::DomainInfo.new(Lang::Environment.new)
        end
      end
    end
  end
end
