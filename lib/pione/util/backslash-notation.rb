module Pione
  module Util
    module BackslashNotation
      class << self
        def apply(s)
          s.to_s.gsub(/\\(.)/){$1}
        end
      end
    end
  end
end
