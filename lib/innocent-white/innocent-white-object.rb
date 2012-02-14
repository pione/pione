require 'innocent-white/util'

module InnocentWhite
  class InnocentWhiteObject
    def uuid
      @__uuid__ || @__uuid__ = Util.uuid
    end
  end
end
