module Pione
  # PioneObject is a Base class for PIONE system.
  class PioneObject
    # Returns this object's uuid.
    # @return [String]
    #   UUID string
    def uuid
      @__uuid__ ||= Pione.generate_uuid
    end

    # Finalizes this object.
    # @return [void]
    def finalize
      # do nothing
    end
  end
end
