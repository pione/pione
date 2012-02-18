require 'innocent-white/util'

module InnocentWhite
  class InnocentWhiteObject
    def uuid
      @__uuid__ ||= Util.uuid
    end

    # Finalize the object.
    def finalize
      # none
    end
  end
end
