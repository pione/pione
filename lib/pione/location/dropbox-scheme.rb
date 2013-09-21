module Pione
  module Location
    # Dropbox is a scheme for dropbox.
    class DropboxScheme < LocationScheme('dropbox', :storage => true)
      # @api private
      COMPONENT = [:scheme, :path]
    end
  end
end
