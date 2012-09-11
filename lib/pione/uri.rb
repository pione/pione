require 'uri'

module Pione
  module URI
    class Local < ::URI::Generic
      COMPONENT = [:scheme, :path]

      def self.build(args)
        super(URI::Util::make_components_hash(self, args))
      end

      # Return true if the path represents a directory.
      def directory?
        path[-1] == '/'
      end

      # Return true if the path represents a file.
      def file?
        not(directory?)
      end

      def absolute
        ::URI.parse("%s:%s/" % [scheme, File.realpath(path)])
      end
    end

    class Dropbox < ::URI::Generic
      COMPONENT = [:scheme, :path]
    end
  end
end

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
