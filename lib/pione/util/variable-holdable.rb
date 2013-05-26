module Pione
  module Util
    module VariableHoldable
      class << self
        def included(subclass)
          class << subclass
            attr_reader :variable_holders

            def hold_variable(name)
              (@variable_holders ||= []) << name
            end

            def hold_variables(*names)
              names.each {|name| hold_variable(name)}
            end

            attr_reader :variable_included

            def include_variable(b)
              @variable_included = b
            end
          end
        end
      end

      def include_variable?
        unless self.class.variable_included.nil?
          return self.class.variable_included
        else
          self.class.variable_holders.any? do |var|
            val = instance_variable_get("@%s" % var)
            val == self or val.nil? ? false : val.include_variable?
          end
        end
      end
    end
  end
end
