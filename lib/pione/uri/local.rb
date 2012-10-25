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
  end
end
