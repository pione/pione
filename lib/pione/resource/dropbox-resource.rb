module Pione
  module Resource
    class Dropbox < BasicResource
      def self.init(tuple_space_server)
        @session = DropboxSession.new.new(
          Global.dropbox_consumer_key,
          Global.dropbox_consumer_secret
        )
        key = tuple_space_server.read(
          Tuple[:attribute].new("dropbox_access_token_key", nil)
        )
        secret = tuple_space_server.read(
          Tuple[:attribute].new("dropbox_access_token_secret", nil)
        )
        @session.set_access_token(key, secret)
      end

      def self.session
        @session
      end

      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(Pione::URI::Dropbox)
        @path = uri.path
        @client = DropboxClient.new(self.class.session, "app_folder")
      end

      def create(data)
        @client.put_file(@path, StringIO.new(data))
      end

      def read
        @client.get_file(@path)
      end

      def update(data)
        @client.put_file(@path, StringIO.new(data), true)
      end

      def delete
        @client.delete_file(@path)
      end

      def mtime
        metadata = @client.metadata(@path)
        Time.parse(metadata["modified"])
      end

      def entries
        metadata = @client.metadata(@path)
        metadata["contents"].select{|entry| not(entry["is_dir"]) and not(entry["is_deleted"])}.map do |entry|
          Resource["dropbox:%s" % entry["path"]]
        end
      end

      def basename
        @path.basename.to_s
      end

      def exist?
        begin
          metadata = @client.metadata(@path)
          return not(metadata["is_deleted"])
        rescue DropboxError
          return false
        end
      end

      def link_to(dist)
        content = get(@path)
        File.open(dist, "w") do |out|
          out.write content
        end
      end

      def link_from(other)
        update(File.read(other))
      end

      def shift_from(other)
        @client.file_move(other, @path)
      end
    end
  end
end
