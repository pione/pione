require 'uri'

module InnocentWhite
  module URI
    class Local < ::URI::Generic
      COMPONENT = [:scheme, :path]

      # Return true if the path represents a directory.
      def directory?
        path[-1] == '/'
      end

      # Return true if the path represents a file.
      def file?
        not(directory?)
      end
    end
  end
end

module URI
  @@schemes['LOCAL'] = InnocentWhite::URI::Local
end
