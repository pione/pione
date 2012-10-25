module Pione
  module Transformer
    module TransformerModule
      class << self
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

        def create_pair_by(*mods)
          mods.inject([]) do |list, mod|
            list += create_pair(mod)
          end
        end

        def create_pair(mod)
          (mod.methods.sort - Object.methods.sort).map{|m| [m, mod]}
        end
      end
    end
  end
end
