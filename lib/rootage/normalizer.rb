module Rootage
  # `Normalizer` is a utility module that normalizes values into normalization
  # types. If values cannot normalize, this method raises
  # `NormalizerValueError`. Normalization types are followings:
  #
  #  - boolean
  #  - string
  #  - integer
  #  - positive_integer
  #  - float
  #  - date
  #
  # And array is treated as special type, this type means the value should be
  # included in the array.
  module Normalizer
    class << self
      # Normalize the value as the normalization type.
      #
      # @param type [Symbol]
      #   normalization type
      # @param val [Object]
      #   source value
      # @return [Object]
      #   the normalized value
      def normalize(type, val)
        if respond_to?(type, true)
          send(type, val)
        else
          raise NormalizerTypeError.new(type)
        end
      end

      # Set normalization function.
      #
      # @param name [Symbol]
      #   normalization type name
      # @yieldparam val [Object]
      #   source object
      def set(name, &block)
        singleton_class.instance_eval do
          define_method(name, &block)
        end
      end

      private

      def boolean(val)
        BooleanValue.of(val)
      rescue => e
        raise NormalizerValueError.new(:boolean, val, e.message)
      end

      def string(val)
        val.to_s
      rescue => e
        raise NormalizerValueError.new(:string, val, e.message)
      end

      def symbol(val)
        val.to_sym
      rescue => e
        raise NormalizerValueError.new(:symbol, val, e.message)
      end

      def symbol_downcase(val)
        val.to_s.downcase.to_sym
      rescue => e
        raise NormalizerValueError.new(:symbol_downcase, val, e.message)
      end

      def symbol_uppercase(val)
        val.to_s.uppercase.to_sym
      rescue => e
        raise NormalizerValueError.new(:symbol_uppercase, val, e.message)
      end

      def integer(val)
        val.to_i
      rescue => e
        raise NormalizerValueError.new(:integer, val, e.message)
      end

      def positive_integer(val)
        n = integer(val)
        if n > 0
          n
        else
          raise NormalizerValueError.new(:positive_integer, val, "It should be a positive integer.")
        end
      end

      def float(val)
        val.to_f
      rescue => e
        raise NormalizerValueError.new(:float, val, e.message)
      end

      def path(val)
        if val.is_a?(Pathname)
          val
        else
          Pathname.new(val)
        end
      rescue => e
        raise NormalizerValueError.new(:path, val, e.message)
      end

      def date(val)
        if val.is_a?(Date)
          val
        else
          Date.iso8601(val)
        end
      rescue => e
        raise NormalizerValueError.new(:date, val, e.message)
      end

      def uri(val)
        URI.parse(val)
      rescue => e
        raise NormalizerValueError.new(:uri, val, e.message)
      end
    end
  end

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
        when Number
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
