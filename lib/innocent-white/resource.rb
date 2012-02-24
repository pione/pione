require 'innocent-white/uri'

module InnocentWhite
  module Resource
    class ResourceException < Exception
      def initialize(uri)
        @uri = uri
      end
    end

    class NotFound < ResourceException; end

    @@schemes = {}

    def self.[](uri)
      @@schemes[uri.scheme].new(uri)
    end

    class Base
      def create(data)
        raise NotImplementedError
      end

      def read
        raise NotImplementedError
      end

      def update(data)
        raise NotImplementedError
      end

      def delete
        raise NotImplementedError
      end
    end

    class Local < Base
      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(URI::Local)
        @path = uri.path
      end

      def create(data)
        dir = File.dirname(@path)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        File.open(@path, "w+"){|file| file.write(data)}
      end

      def read
        if File.exist?(@path)
          File.read(@path)
        else
          raise NotFound.new(@uri)
        end
      end

      def update(data)
        if File.exist?(@path)
          File.open(@path, "w+"){|file| file.write(data)}
        else
          raise NotFound.new(@uri)
        end
      end

      def delete
        File.delete(@path)
      end
    end

    @@schemes["local"] = Local
  end
end
