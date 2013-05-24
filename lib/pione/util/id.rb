module Pione
  module Util
    # ID is a set of ID generators.
    module TaskID
      # Make a task id by input data names and parameters.
      #
      # @param inputs [Array<Tuple::DataTuple>]
      #   input data tuples
      # @param params [Model::Parameters]
      #   parameters object
      # @return [String]
      #   task's digest string
      def generate(inputs, params)
        input_names = inputs.map{|t| t.name}
        Digest::MD5.hexdigest("%s,%s" % [input_names.join(":"), params.textize])
      end
      module_function :generate
    end

    module DomainID
      # Make a domain id by rule, inputs, and parameters.
      #
      # @param rule [Component::Rule]
      #   rule
      # @param inputs [Array<Tuple::DataTuple>]
      #   input data tuples
      # @param params [Model::Parameters]
      #   parameters
      # @return [String]
      #   domain id string
      def generate(rule, inputs, params)
        package_name = rule.rule_expr.package_expr.name
        rule_name = rule.rule_expr.name
        "%s-%s_%s" % [package_name, rule_name, TaskID.generate(inputs, params)]
      end
      module_function :generate
    end
  end
end
