module Pione
  module URIScheme
    # Dropbox is a scheme for dropbox.
    class DropboxScheme < BasicScheme('dropbox')
      # @api private
      COMPONENT = [:scheme, :path]
    end
  end
end
