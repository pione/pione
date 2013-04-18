require_relative '../test-util'

TestUtil::FTPServer.start

describe 'Location::FTPLocation' do
  if TestUtil::FTPServer.enabled?
    before do
      TestUtil::FTPServer::FS.clear
      @ftp = TestUtil::FTPServer.make_location(Temppath.create)
    end

    it 'should create a file' do
      @ftp.create("A")
      @ftp.should.exist
      @ftp.read.should == "A"
    end

    it 'should raise exception when the file exists already' do
      @ftp.create("A")
      should.raise(Location::ExistAlready) {@ftp.create("B")}
    end

    it 'should append data' do
      @ftp.create("A")
      @ftp.append("B")
      @ftp.read.should == "AB"
    end

    it "should not raise exception when the file doesn't exist" do
      @ftp.should.not.exist
      @ftp.append("A")
      @ftp.read.should == "A"
    end

    it 'should read a file' do
      @ftp.create("A")
      @ftp.read.should == "A"
    end

    it 'should update a file' do
      @ftp.create("A")
      @ftp.read.should == "A"
      @ftp.update("B")
      @ftp.read.should == "B"
      @ftp.update("C")
      @ftp.read.should == "C"
    end

    it 'should delete a file' do
      should.not.raise {@ftp.delete}
      @ftp.should.not.exist
      should.not.raise {@ftp.delete}
    end

    it 'should link' do
      desc = Location[Temppath.create].tap {|x| x.create("A")}
      @ftp.link(desc)
      @ftp.read.should == "A"
    end

    it 'should move' do
      dest = Location[Temppath.create]
      @ftp.create("A")
      @ftp.move(dest)
      dest.read.should == "A"
      @ftp.should.not.exist
    end

    it 'should copy' do
      dest = Location[Temppath.create]
      @ftp.create("A")
      @ftp.copy(dest)
      dest.read.should == "A"
      @ftp.read.should == "A"
    end

    it 'should turn' do
      dest = Location[Temppath.create]
      @ftp.create("A")
      @ftp.turn(dest)
      dest.read.should == "A"
      @ftp.read.should == "A"
    end

    it 'should get mtime information' do
      @ftp.create("A")
      @ftp.mtime.should.kind_of Time
    end

    it 'should get size information' do
      @ftp.create("ABC")
      @ftp.size.should == 3
    end

  else
    it 'cannot do ftp test in your environment' do
      true.should.true
    end
  end
end
