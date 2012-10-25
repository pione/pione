module Pione
  # PioneObject is a base class for PIONE system.
  class PioneObject
    # Checks argument type and raises a type error if the value is not kind of
    # the type.
    def check_argument_type(val, klass)
      raise TypeError.new(val) unless val.kind_of?(klass)
    end

    # Returns this object's uuid.
    # @return [String]
    #   UUID string
    def uuid
      @__uuid__ ||= Pione.generate_uuid
    end

    def remote_object_uri
      @remote_object ||= DRbObject.new(self)
      @remote_object.__drburi
    end

    # Finalizes this object.
    # @return [void]
    def finalize
      # do nothing
    end
  end
end
