require 'webrick'
require 'webrick/https'

module Pione
  module TestHelper
    class WebServer
      class << self
        def start(*args)
          new(*args).tap {|x| x.start}
        end
      end

      def initialize(document_root, option={})
        logger = WEBrick::Log.new(StringIO.new("", "w"))
        # modify document root
        document_root = document_root.local.path if document_root.kind_of?(Pione::Location::DataLocation)

        # setup options
        _option = {DocumentRoot: document_root}
        _option[:Port] = 54673 unless option[:Port]
        _option[:Logger] = logger unless option[:Logger]
        _option[:AccessLog] = logger unless option[:AccessLog]

        # make webrick
        @server = WEBrick::HTTPServer.new(_option)
      end

      def root
        Pione::Location["http://localhost:%s/" % port]
      end

      def port
        @server.config[:Port]
      end

      def start
        @thread = Thread.new do
          retriable(on: WEBrick::ServerError, tries: 10, interval: 2) do
            @server.start
          end
        end
      end

      def terminate
        @server.shutdown
        @thread.kill.join
      end
    end
  end
end
