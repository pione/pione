module Pione
  module Util
    module PackageParametersList
      class << self
        # Print parameters list of the package.
        #
        # @param package [Component::Package]
        #   package
        def print(package)
          unless package.params.empty?
            print_params_by_block("Basic Parameters", package.params.basic)
            print_params_by_block("Advanced Parameters", package.params.advanced)
          else
            puts "there are no user parameters in %s" % package.name
          end
        end

        private

        # Print parameters by block.
        def print_params_by_block(header, target_params)
          unless target_params.empty?
            puts "%s:" % header
            target_params.data.each do |var, val|
              puts "  %s := %s" % [var.name, val.textize]
            end
          end
        end
      end
    end
  end
end
