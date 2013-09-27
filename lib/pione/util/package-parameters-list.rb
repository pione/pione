module Pione
  module Util
    module PackageParametersList
      class << self
        # Print parameter list of the package.
        #
        # @param package [Package::Package]
        #   package
        def print(env, package_id)
          definition = env.package_get(Lang::PackageExpr.new(package_id: package_id))
          params = definition.param_definition.values
          if params.size > 0
            group = params.group_by {|param| param.type}
            print_params_by_block("Basic Parameters", group[:basic]) if group[:basic]
            print_params_by_block("Advanced Parameters", group[:advanced]) if group[:advanced]
          else
            puts "there are no user parameters in %s" % env.current_package_id
          end
        end

        private

        # Print parameters by block.
        def print_params_by_block(header, target_params)
          unless target_params.empty?
            puts "%s:" % header
            target_params.each do |param|
              puts "  %s := %s" % [param.name, param.value.textize]
            end
          end
        end
      end
    end
  end
end
