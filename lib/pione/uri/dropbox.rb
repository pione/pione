module Pione
  module URI
    # Dropbox is a scheme for dropbox.
    class Dropbox < ::URI::Generic
      # @api private
      COMPONENT = [:scheme, :path]
    end

    ::URI.install_scheme('DROPBOX', Dropbox)
  end
end
