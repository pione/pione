module Pione
  module Transformer
    # TransformerModule enables parslet's transforms to be defined by multiple
    # modules.
    module TransformerModule
      class << self
        # @api private
        def included(mod)
          singleton = class << mod; self; end
          create_pair_by(Parslet, Parslet::Transform).each do |name, orig|
            singleton.__send__(:define_method, name) do |*args, &b|
              orig.__send__(name, *args, &b)
            end
          end

          class << mod
            def included(klass)
              name = :@__transform_rules
              klass_rules = klass.instance_variable_get(name)
              klass_rules = klass_rules ? klass_rules + rules : rules
              klass.instance_variable_set(name, klass_rules)
            end
          end
        end

        private

        # Create module and the methods pair by modules.
        #
        # @api private
        def create_pair_by(*mods)
          mods.inject([]) do |list, mod|
            list + (mod.methods.sort - Object.methods.sort).map{|m| [m, mod]}
          end
        end
      end
    end
  end
end
