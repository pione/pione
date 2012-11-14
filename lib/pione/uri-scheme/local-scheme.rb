module Pione
  module URIScheme
    # Local represents local file system path.
    # @example
    #   # absolute path form
    #   local:/home/keita/
    # @example
    #   # relative path form
    #   local:./test.txt
    class LocalScheme < BasicScheme('local')
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
        URI.parse("%s:%s" % [scheme, File.realpath(path)])
      end
    end
  end
end
