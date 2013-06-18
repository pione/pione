require_relative "../test-util"
require 'webrick'

describe "Pione::Location::HTTPLocation" do
  before do
    @path = File.join(File.dirname(__FILE__), "spec_http-location")
    logger = WEBrick::Log.new(StringIO.new("", "w"))
    @server = WEBrick::HTTPServer.new(DocumentRoot: @path, Port: 54673, Logger: logger, AccessLog: logger)
    Thread.new { @server.start }
  end

  after do
    @server.shutdown
  end

  def location(path)
    Location["http://127.0.0.1:%s%s" % [@server.config[:Port], path]]
  end

  it "should not be writable" do
    location("/a.txt").should.not.be.writable
  end

  it "should read files" do
    location("/a.txt").read.should == "A"
    location("/b.txt").read.should == "AB"
    location("/c.txt").read.should == "ABC"
    location("/dir/d.txt").read.should == "ABCD"
  end

  it "should get size" do
    location("/a.txt").size.should == 1
    location("/b.txt").size.should == 2
    location("/c.txt").size.should == 3
    location("/dir/d.txt").size.should == 4
  end

  it "should get mtime" do
    location("/a.txt").mtime.to_s.should == File.mtime(File.join(@path, "a.txt")).to_s
    location("/b.txt").mtime.to_s.should == File.mtime(File.join(@path, "b.txt")).to_s
    location("/c.txt").mtime.to_s.should == File.mtime(File.join(@path, "c.txt")).to_s
    location("/dir/d.txt").mtime.to_s.should == File.mtime(File.join(@path, "dir", "d.txt")).to_s
  end

  it "should exist" do
    location("/a.txt").should.exist
    location("/b.txt").should.exist
    location("/c.txt").should.exist
    location("/dir/d.txt").should.exist
  end

  it "should not exist" do
    location("/d.txt").should.not.exist
    location("/dir").should.not.exist
  end

  it "should be files" do
    location("/a.txt").should.be.file
    location("/b.txt").should.be.file
    location("/c.txt").should.be.file
    location("/dir/d.txt").should.be.file
  end

  it "should not be files" do
    location("/d.txt").should.not.file
    location("/dir").should.not.file
  end

  it "should not be directories" do
    location("/a.txt").should.not.be.directory
    location("/b.txt").should.not.be.directory
    location("/c.txt").should.not.be.directory
    location("/dir/d.txt").should.not.be.directory
    location("/d.txt").should.not.directory
    location("/dir").should.not.directory
  end
end

