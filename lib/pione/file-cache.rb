module Pione
  class FileCache < PioneObject
    include DRbUndumped

    PORT = 54003
    TIMEOUT = 5
    MAX_RETRY_NUMBER = 5
    UUID = ""

    class InstanceError < StandardError; end

    # Return the provider instance.
    def self.instance(data = {}, i=0)
      if i >= MAX_RETRY_NUMBER
        raise InstanceError
      end
      data = {} unless data.kind_of?(Hash)
      # check DRb service
      begin
        DRb.current_server
      rescue
        DRb.start_service
      end
      # remote object
      begin
        # get provider reference
        cache = DRbObject.new_with_uri(uri)
        cache.uuid # check the server exists
        return cache
      rescue
        begin
          # create new provider
          provider = self.new(data)
          provider.drb_service = DRb::DRbServer.new(uri, provider)
          return DRbObject.new_with_uri(uri)
        rescue Errno::EADDRINUSE
          # retry
          instance(data, i+1)
        end
      end
    end

    def self.file_cache_uri(data={})
      port = PORT
      if data.has_key?(:file_cache_port)
        port = data[:file_cache_port]
      end
      return "druby://localhost:%s" % port
    end

    # Terminate tuple space provider.
    def self.terminate
      # terminate message as remote procedure call causes connection error
      begin
        instance.terminate
      rescue
        # do nothing
      end
    end

    def initialize
      super()
      @table = {}
      @terminated = false
      @tmpdir = Dir.mktmpdir("pione-file-cache")
    end

    def alive?
      not(@terminated)
    end

    # Gets cached data path from the uri resource.
    def get(uri)
      unless @table.has_key?(uri)
        cache = Tempfile.new("", @tmpdir)
        path = cache.path
        cache.close(false)
        Resource[uri].copy_to(path)
        @table[uri] = path
      end
      return @table[uri]
    end

    # Puts the data to uri resource and caches it in local.
    def put(src, uri)
      cache = Tempfile.new("", @tmpdir)
      path = cache.path
      cache.close(false)
      FileUtils.mv(src, path)
      FileUtils.symlink(path, src)
      @table[uri] = path
      Resource[uri].copy_from(path)
    end

  end
end
