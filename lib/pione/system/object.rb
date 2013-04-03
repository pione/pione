module Pione
  module System
    # PioneObject is a base class for PIONE system.
    class PioneObject
      # Checks argument type. Raises a type error if the value is not kind of
      # the type.
      # @param [Object] val
      #   check target
      # @param [Class] klass
      #   expected type
      # @return [void]
      def check_argument_type(val, klass)
        raise TypeError.new(val) unless val.kind_of?(klass)
      end

      # Returns true.
      def ping
        true
      end

      # Returns this object's uuid.
      # @return [String]
      #   UUID string
      def uuid
        @__uuid__ ||= Util.generate_uuid
      end

      # Finalizes this object.
      # @return [void]
      def finalize
        # do nothing
      end
    end
  end
end
