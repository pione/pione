require_relative '../test-util'
require_relative 'location-behavior'

Util::FTPServer.start(Util::FTPOnMemoryFS.new)

describe 'Location::FTPLocation' do
  before do
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
  end

  behaves_like "location"
end
