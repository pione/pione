require_relative "../test-util"
require_relative "http-behavior"
require 'webrick'
require 'webrick/https'

describe "Pione::Location::HTTPSLocation" do
  before do
    @path = File.join(File.dirname(__FILE__), "spec_http-location")
    logger = WEBrick::Log.new(StringIO.new("", "w"))
    @server = WEBrick::HTTPServer.new(
      DocumentRoot: @path,
      Port: 54673,
      Logger: logger,
      AccessLog: logger,
      SSLEnable: true,
      SSLCertName: [["CN", WEBrick::Utils.getservername]]
    )
    Thread.new do
      $stderr = StringIO.new("", "w")
      begin
        @server.start
      rescue WEBrick::ServerError
        sleep 1
        @server.start
      end
      $stderr = STDOUT
    end
  end

  after do
    @server.shutdown
  end

  def location(path)
    Location["https://127.0.0.1:%s%s" % [@server.config[:Port], path]]
  end

  behaves_like "http"
end
