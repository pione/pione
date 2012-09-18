module Pione
  # URI is a URI module for PIONE system.
  module URI
    # Local is local file system path representation.
    # @example
    #   # absolute path form
    #   local:/home/keita/
    # @example
    #   # relative path form
    #   local:./test.txt
    class Local < ::URI::Generic
      # @api private
      COMPONENT = [:scheme, :path]

      # @api private
      def self.build(args)
        super(URI::Util::make_components_hash(self, args))
      end

      # Returns true if the path represents a directory.
      # @return [Boolean]
      #   true if the path represents a directory
      def directory?
        path[-1] == '/'
      end

      # Returns true if the path represents a file.
      # @return [Boolean]
      #   true if the path represents a file
      def file?
        not(directory?)
      end

      # Returns absolute path.
      # @return [::URI]
      #   URI with absolute path
      def absolute
        ::URI.parse("%s:%s/" % [scheme, File.realpath(path)])
      end
    end

    # Dropbox is dropbox representation.
    class Dropbox < ::URI::Generic
      # @api private
      COMPONENT = [:scheme, :path]
    end
  end
end

# URI extention for PIONE system.
# @api private
module URI
  @@schemes['LOCAL'] = Pione::URI::Local
  @@schemes['DROPBOX'] = Pione::URI::Dropbox

  class Parser
    alias :orig_split :split

    # special split method for local scheme.
    def split(uri)
      if uri.split(":").first == "local"
        scheme = "local"
        path = uri[6..-1]
        return [scheme, nil, nil, nil, nil, path, nil, nil, nil]
      else
        return orig_split(uri)
      end
    end
  end
end
