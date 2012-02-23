require 'uri'

module InnocentWhite
  module URI
    class Local < ::URI::Generic
      COMPONENT = [:scheme, :path]

      def directory?
        path[-1] == '/'
      end

      def file?
        not(directory?)
      end
    end
  end
end

module URI
  @@schemes['LOCAL'] = InnocentWhite::URI::Local
end
