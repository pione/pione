module Pione
  module Location
    # DropboxLocation represents locations on Dropbox server.
    class DropboxLocation < BasicLocation
      set_scheme "dropbox"

      class << self
        attr_reader :session

        # Initialize dropbox settings.
        #
        # @param tuple_space_server [TupleSpaceServer]
        #   tuple space server
        # @return [void]
        def self.init(tuple_space_server)
          tuple_consumer_key = Tuple[:attribute].new("dropbox_consumer_key", nil)
          tuple_consumer_secret = Tuple[:attribute].new("dropbox_consumer_secret", nil)
          tuple_access_token_key = Tuple[:attribute].new("dropbox_access_token_key", nil)
          tuple_access_token_secret = Tuple[:attribute].new("dropbox_access_token_secret", nil)

          consumer_key = tuple_space_server.read(tuple_consumer_key, 0).value rescue nil
          consumer_secret = tuple_space_server.read(tuple_consumer_secret, 0).value rescue nil
          access_token_key = tuple_space_server.read(tuple_access_token_key, 0).value rescue nil
          access_token_secret = tuple_space_server.read(tuple_access_token_secret, 0).value rescue nil

          @session = DropboxSession.new(consumer_key, consumer_secret)
          @session.set_access_token(access_token_key, access_token_secret)
        end

        # Share dropbox's access token with PIONE agents.
        #
        # @param tuple_space_server [TupleSpaceServer]
        #   tuple space server
        # @param consumer_key [String]
        #   consumer key
        # @param consumer_secret [String]
        #   consumer secret
        # @return [void]
        def share_access_token(tuple_space_server, consumer_key, consumer_secret)
          access_token = session.get_access_token
          [ Tuple[:attribute].new("dropbox_consumer_key", consumer_key),
            Tuple[:attribute].new("dropbox_consumer_secret", consumer_secret),
            Tuple[:attribute].new("dropbox_access_token_key", access_token.key),
            Tuple[:attribute].new("dropbox_access_token_secret", access_token.secret)
          ].each {|tuple| tuple_space_server.write(tuple) }
        end

        # Return true if dropbox session is authorized.
        #
        # @return [Boolean]
        #   true if dropbox session is authorized
        def ready?
          @session.authorized?
        end

        # Set the session.
        #
        # @param session [String]
        #    dropbox session
        # @return [void]
        def self.set_session(session)
          @session = session
        end
      end

      def initialize(uri)
        super(uri)
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
        @client.file_delete(@path)
      end

      def mtime
        metadata = @client.metadata(@path)
        Time.parse(metadata["modified"])
      end

      def entries
        metadata = @client.metadata(@path)
        if not(metadata["is_dir"]) or metadata["is_deleted"]
          raise NotFound.new(self)
        end
        metadata["contents"].select{|entry| not(entry["is_dir"]) and not(entry["is_deleted"])}.map do |entry|
          Location["dropbox:%s" % entry["path"]]
        end
      end

      def exist?
        metadata = @client.metadata(@path)
        return not(metadata["is_deleted"])
      rescue DropboxError
        return false
      end

      def move(dest)
        if dest.scheme == scheme
          @client.file_move(@path, dest.path)
        else
          copy(dest)
          delete
        end
      end

      def copy(dest)
        if dest.scheme == scheme
          @client.file_copy(@path, dest.path)
        else
          dest.update(read)
        end
      end

      def link(orig)
        if orig.scheme == scheme
          orig.copy(link)
        else
          update(orig.read)
        end
      end

      def turn(dest)
        copy(dest)
      end
    end
  end
end
