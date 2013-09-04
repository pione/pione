require_relative "../test-util"
require_relative "http-behavior"
require 'webrick'

describe "Pione::Location::HTTPLocation" do
  before do
    @path = File.join(File.dirname(__FILE__), "spec_http-location")
    @server = TestUtil::WebServer.start(@path)
  end

  after do
    @server.terminate
  end

  def location(path)
    Location["http://127.0.0.1:%s%s" % [@server.port, path]]
  end

  behaves_like "http"
end

