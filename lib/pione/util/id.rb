module Pione
  module Util
    # ID is a set of ID generators.
    module TaskID
      # Make a task id by input data names and parameters.
      def generate(inputs, params)
        # NOTE: auto variables are ignored
        param_set = params.filter(["I", "INPUT", "O", "OUTPUT", "*"])
        inputs = inputs.map {|t| t.is_a?(Tuple::DataTuple) ? t.name : t}
        Digest::MD5.hexdigest("%s::%s" % [inputs.join(":"), param_set.textize])
      end
      module_function :generate
    end

    module DomainID
      # Make a domain id based on package id, rule name, inputs, and parameter set.
      def generate(package_id, rule_name, inputs, params)
        "%s:%s:%s" % [package_id, rule_name, TaskID.generate(inputs.flatten, params)]
      end
      module_function :generate
    end

    module PackageID
      # Generate package id from the package name in the environment.
      def generate(env, package_name)
        begin
          env.package_get(PackageExpr.new(name: package_name, package_id: package_name))
          i = 0
          loop do
            i += 1
            name = "%s-%s" % [package_name, i]
            unless env.package_ids.include?(name)
              env.package_ids << name
              return name
            end
          end
        rescue Lang::UnboundError
          return package_name
        end
      end
      module_function :generate
    end
  end
end
