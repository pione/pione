module Pione
  module Location
    # DropboxLocation represents locations on Dropbox server.
    class DropboxLocation < DataLocation
      set_scheme "dropbox"

      define(:need_caching, true)
      define(:real_appendable, false)
      define(:writable, true)

      class << self
        attr_reader :client

        # Return true if Dropbox's access token cache exists.
        #
        # @return [Boolean]
        #   true if Dropbox's access token cache exists
        def cached?
          cache = Pathname.new("~/.pione/dropbox_api.cache").expand_path
          return (cache.exist? and cache.read.size > 0)
        end

        # Setup Dropbox location for CUI client. This method gets Dropbox's
        # access token from cache file or OAuth2.
        #
        # @param tuple_space [TupleSpaceServer]
        #   tuple space
        # @return [void]
        def setup_for_cui_client(tuple_space)
          return if @client

          access_token = nil
          cache = Pathname.new("~/.pione/dropbox_api.cache").expand_path

          if cache.exist?
            # load access token from cache file
            access_token = cache.read
          else
            # get access token by OAtuh2
            setup_consumer_key_and_secret
            flow = auth_by_oauth2flow_no_redirect
            access_token, user_id = get_code_for_cui_client(flow)

            # cache session
            cache.open("w+") {|c| c.write access_token}
          end

          # make a client
          @client = DropboxClient.new(access_token)

          # share access token in tuple space
          share_access_token(tuple_space, access_token)
        end

        # Enable Dropbox locations. This method get an access token from the
        # tuple space and make a Dropbox client. This assumes to be called from
        # task worker agents.
        #
        # @param tuple_space_server [TupleSpaceServer]
        #   tuple space server
        # @return [void]
        def enable(tuple_space)
          tuple = TupleSpace::AttributeTuple.new("dropbox_access_token", nil)
          if tuple_access_token = tuple_space.read!(tuple)
            @client = DropboxClient.new(tuple_access_token.value)
          else
            raise DropboxLocationUnavailable.new("There is no access token.")
          end
        end

        def rebuild(path)
          Location["dropbox:%s" % path]
        end

        # Setup Dropbox's consumer key and secret. They are loaded from a YAML
        # file "dropbox_api.yml" at PIONE's home directory.
        #
        # @return [void]
        def setup_consumer_key_and_secret
          path = Pathname.new("~/.pione/dropbox_api.yml").expand_path
          if File.exist?(path)
            api = YAML.load(path.read)
            @consumer_key = api["key"]
            @consumer_secret = api["secret"]
          else
            raise DropboxLocationUnavailable.new("There are no consumer key and consumer secret.")
          end
        end

        # Authorize dropbox account by `DropboxOAuth2FlowNoRedirect`.
        #
        # @return [String]
        #   authorize URL
        def auth_by_oauth2flow_no_redirect
          if @consumer_key and @consumer_secret
            return DropboxOAuth2FlowNoRedirect.new(@consumer_key, @consumer_secret)
          else
            raise DropboxLocationUnavailable.new("There are no consumer key and consumer secret.")
          end
        end

        # Authorize dropbox account by `DropboxOAuth2Flow`.
        #
        # @param redirect [String]
        #   redirect URL
        # @param session [Hash]
        #   session
        # @return [String]
        #   authorize URL
        def auth_by_oauth2flow(redirect, session)
          if @consumer_key and @consumer_secret
            return DropboxOAuth2Flow.new(@consumer_key, @consumer_secret, redirect, session, :dropbox_auth_csrf_token)
          else
            raise DropboxLocationUnavailabel.new("There are no consumer key and consumer secret.")
          end
        end

        # Share dropbox's access token with PIONE agents.
        #
        # @param tuple_space_server [TupleSpaceServer]
        #   tuple space server
        # @param access_token [String]
        #   access token
        # @return [void]
        def share_access_token(tuple_space_server, access_token)
          tuple = TupleSpace::AttributeTuple.new("dropbox_access_token", access_token)
          tuple_space_server.write(tuple)
        end

        # Get code for CUI client.
        #
        # @return [Array]
        #   access token and Dropbox user ID
        def get_code_for_cui_client(flow)
          puts '1. Go to: %s' % flow.start
          puts '2. Click "Allow"'
          puts '3. Copy the authorization code'
          print 'Enter the authorization code here: '
          code = STDIN.gets.strip
          flow.finish(code)
        end
      end

      def initialize(uri)
        super(uri)
      end

      def create(data)
        if exist?
          raise ExistAlready.new(self)
        else
          client.put_file(@path.to_s, StringIO.new(data))
        end
        return self
      end

      def read
        exist? ? client.get_file(@path.to_s) : (raise NotFound.new(self))
      end

      def update(data)
        client.put_file(@path.to_s, StringIO.new(data), true)
        return self
      end

      def delete
        if exist?
          client.file_delete(@path.to_s)
        end
      end

      # dropbox have "modified" time only, therefore ctime is not implemented

      def mtime
        metadata = client.metadata(@path.to_s)
        Time.parse(metadata["modified"])
      end

      def size
        metadata = client.metadata(@path.to_s)
        return metadata["bytes"]
      end

      def entries(option={})
        rel_entries(option).map {|entry| rebuild(@path + entry)}
      end

      def rel_entries(option={})
        list = []
        raise NotFound.new(self) if not(directory?)

        metadata = client.metadata(@path.to_s)
        metadata["contents"].select{|entry| not(entry["is_deleted"])}.each do |entry|
          list << entry["path"].sub(@path.to_s, "").sub(/^\//, "")
          entry_location = rebuild(@path + File.basename(entry["path"]))
          if option[:rec] and entry_location.directory?
            _list = entry_location.rel_entries(option).map {|subentry| entry + subentry}
            list = list + _list
          end
        end
        return list
      end

      def exist?
        metadata = client.metadata(@path.to_s)
        return not(metadata["is_deleted"])
      rescue DropboxLocationUnavailable
        raise
      rescue DropboxError
        return false
      end

      def file?
        begin
          metadata = client.metadata(@path.to_s)
          return (not(metadata["is_dir"]) and not(metadata["is_deleted"]))
        rescue DropboxError
          # when there exists no files and no directories
          false
        end
      end

      def directory?
        begin
          metadata = client.metadata(@path.to_s)
          return (metadata["is_dir"] and not(metadata["is_deleted"]))
        rescue DropboxError
          # when there exists no files and no directories
          false
        end
      end

      def mkdir
        unless exist?
          client.file_create_folder(@path.to_s)
        end
      end

      def move(dest)
        if dest.scheme == scheme
          client.file_move(@path.to_s, dest.path)
        else
          copy(dest)
          delete
        end
      end

      def copy(dest)
        raise NotFound.new(self) unless exist?

        if dest.scheme == scheme
          client.file_copy(@path.to_s, dest.path)
        else
          dest.write(read)
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

      private

      # Check availability of Dropbox's access token.
      #
      # @return [void]
      def client
        if self.class.client.nil?
          # raise an exception when Dropbox client isn't enabled
          raise DropboxLocationUnavailable.new("There is no access token.")
        else
          self.class.client
        end
      end
    end
  end
end
