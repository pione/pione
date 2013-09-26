require 'pione/test-helper'
require_relative 'location-behavior'


describe 'Location::FTPLocation' do
  before do
    Util::FTPServer.start(Util::FTPOnMemoryFS.new)
    Util::FTPServer.fs.clear
    @file = Util::FTPServer.make_location(Temppath.create)
    @dir = Util::FTPServer.make_location(Temppath.create)
    (@dir + "A").create("A")
    (@dir + "B").create("B")
    (@dir + "C").create("C")
    (@dir + "D" + "X").create("X")
    (@dir + "D" + "Y").create("Y")
    (@dir + "D" + "Z").create("Z")
  end

  after do
    @file.delete
    @dir.delete
    Util::FTPServer.stop
  end

  behaves_like "location"

  it "should get ftp location from myftp scheme URI" do
    location = Location[URI.parse("myftp://abc:123@myself/output/")]
    location.scheme.should == "ftp"
  end

  it "should move file in the ftp server" do
    location = Util::FTPServer.make_location(Temppath.create)
    (@dir + "A").move(location)
    location.should.exist
    location.read.should == "A"
    (@dir + "A").should.not.exist
  end
end
