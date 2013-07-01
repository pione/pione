require 'webrick'

module TestUtil
  class WebServer
    class << self
      def start(*args)
        new(*args).tap {|x| x.start}
      end
    end

    def initialize(document_root, option={})
      logger = WEBrick::Log.new(StringIO.new("", "w"))
      # modify document root
      document_root = document_root.local.path if document_root.kind_of?(Location::DataLocation)

      # setup options
      _option = {DocumentRoot: document_root}
      _option[:Port] = 54673 unless option[:Port]
      _option[:Logger] = logger unless option[:Logger]
      _option[:AccessLog] = logger unless option[:AccessLog]

      # make webrick
      @server = WEBrick::HTTPServer.new(_option)
    end

    def root
      Location["http://localhost:%s/" % port]
    end

    def port
      @server.config[:Port]
    end

    def start
      @thread = Thread.new { @server.start }
    end

    def terminate
      @server.shutdown
      @thread.kill
    end
  end
end
