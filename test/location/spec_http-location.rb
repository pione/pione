require_relative "../test-util"
require_relative "http-behavior"
require 'webrick'

describe "Pione::Location::HTTPLocation" do
  before do
    @path = File.join(File.dirname(__FILE__), "spec_http-location")
    logger = WEBrick::Log.new(StringIO.new("", "w"))
    @server = WEBrick::HTTPServer.new(DocumentRoot: @path, Port: 54673, Logger: logger, AccessLog: logger)
    Thread.new do
      retriable(on: WEBrick::ServerError, tries: 10, interval: 2) do
        @server.start
      end
    end
  end

  after do
    @server.shutdown
  end

  def location(path)
    Location["http://127.0.0.1:%s%s" % [@server.config[:Port], path]]
  end

  behaves_like "http"
end

