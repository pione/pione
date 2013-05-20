require_relative '../test-util'
require_relative 'location-behavior'

TestUtil::FTPServer.start

describe 'Location::FTPLocation' do
  if TestUtil::FTPServer.enabled?
    before do
      TestUtil::FTPServer::FS.clear
      @file = TestUtil::FTPServer.make_location(Temppath.create)
      @dir = TestUtil::FTPServer.make_location(Temppath.create)
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
  else
    it 'cannot do ftp test in your environment' do
      true.should.true
    end
  end
end
