require 'innocent-white/uri'

module InnocentWhite
  module Resource
    class Local
      def initialize(uri)
        raise ArgumentError unless uri.kind_of?(URI::Local)
        @uri = uri
        @path = uri.path
      end

      def get
        File.read(@path)
      end

      def put(value)
        File.open(@path, "w"){|file| file.write(value)}
      end

      def rm
        File.delete(@path)
      end
    end
  end
end
