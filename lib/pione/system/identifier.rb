module Pione
  module System
    # Identifier is a set of generators for id.
    module Identifier
      # Makes task id by input data names.
      # @param [Array<Pione::Tuple::Data>] inputs
      #   input data tuples
      # @param [Pione::Model::Parameters] params
      #   parameters object
      # @return [String]
      #   task's digest string
      def task_id(inputs, params)
        raise ArgumentError.new(params) unless params.kind_of?(Parameters)
        # FIXME: inputs.flatten?
        input_names = inputs.flatten.map{|t| t.name}
        is = input_names.join("\000")
        ps = params.data.map do |key, val|
          "%s:%s" % [key.textize, val.textize]
        end.join("\000")
        Digest::MD5.hexdigest("#{is}\001#{ps}\001")
      end
      module_function :task_id

      # Makes target domain name by module name, inputs, and outputs.
      # @param [String] package_name
      #   package name
      # @param [String] rule_name
      #   rule name
      # @param [Array<Pione::Tuple::Data>] inputs
      #   input data tuples
      # @param [Pione::Model::Parameters] params
      #   parameters object
      # @return [String]
      #   domain string
      def domain_id(package_name, rule_name, inputs, params)
        "%s-%s_%s" % [package_name, rule_name, task_id(inputs, params)]
      end
      module_function :domain_id

      # Make a domain name by rule path, inputs, and parameters.
      #
      # @param rule [String]
      #   package name
      # @param inputs [Array<Pione::Tuple::Data>]
      #   input data tuples
      # @param params [Model::Parameters]
      #   parameters
      # @return [String]
      #   domain string
      def domain_id3(rule, inputs, params)
        package_name = rule.rule_expr.package.name
        rule_name = rule.rule_expr.name
        return domain_id(package_name, rule_name, inputs, params)
      end
      module_function :domain_id3
    end
  end

  # Short name for Identifier.
  ID = System::Identifier
end
