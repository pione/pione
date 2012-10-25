module Pione
  module URI
    # Dropbox is dropbox representation.
    class Dropbox < ::URI::Generic
      # @api private
      COMPONENT = [:scheme, :path]
    end
  end
end
