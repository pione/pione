module Pione
  module URIScheme
    # Dropbox is a scheme for dropbox.
    class DropboxScheme < BasicScheme('dropbox', :storage => true)
      # @api private
      COMPONENT = [:scheme, :path]
    end
  end
end
