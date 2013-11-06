module Pione
  module Util
    module PackageParametersList
      # Find parameters in the the package.
      #
      # @param env [Lang::Environment]
      #   language environment
      # @param package_id [String]
      #   package ID
      # @return [Array<Array<Lang::ParameterDefinition>>]
      #   basic parameters and advanced parameters
      def self.find(env, package_id)
        # get parameters of the package
        definition = env.package_get(Lang::PackageExpr.new(package_id: package_id))
        params = definition.param_definition.values

        # summarize parameters as basic and advanced
        group = params.group_by {|param| param.type}
        return [(group[:basic] || []), (group[:advanced] || [])]
      end
    end
  end
end
