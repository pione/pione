module Pione
  module Util
    module BooleanValue
      class << self
        # Return boolean value of the object.
        #
        # @param val [Object]
        #   target object
        # @return [Boolean]
        #   boolean of the object
        def of(val)
          case val
          when NilClass
            false
          when TrueClass
            true
          when FalseClass
            false
          when String
            of_string(val)
          when Numeric
            of_number(val)
          else
            raise ArgumentError.new(val)
          end
        end

        private

        # Return boolean value of the string. Ignoring letter cases, "true",
        # "t", "yes", and "y" are true, and "false", "f", "no", and "n" are
        # false. Ohterwise raise `ArgumentError`.
        #
        # @param val [String]
        #   the string
        # @return [Boolean]
        #   boolean of the string
        def of_string(val)
          case val.downcase
          when "true", "t", "yes", "y"
            true
          when "false", "f", "no", "n"
            false
          else
            raise ArgumentError.new(val)
          end
        end

        # Return boolean value of the number. Return true if the number is
        # greater than 0.
        #
        # @param val [Numeric]
        #   the number
        # @return [Boolean]
        #   boolean of the number
        def of_number(val)
          val > 0
        end
      end
    end
  end
end
