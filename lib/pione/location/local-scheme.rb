module Pione
  module Location
    # Local represents local file system path.
    # @example
    #   # absolute path form
    #   local:/home/keita/
    # @example
    #   # relative path form
    #   local:./test.txt
    class LocalScheme < LocationScheme('local', :storage => true)
      # @api private
      COMPONENT = [:scheme, :path]

      # @api private
      def self.build(args)
        super(URI::Util::make_components_hash(self, args))
      end

      # Returns absolute path.
      # @return [URI]
      #   URI with absolute path
      def absolute
        uri = URI.parse("%s:%s" % [scheme, File.expand_path(path, Global.pwd)])
        directory? ? uri.as_directory : uri
      end
    end
  end
end
