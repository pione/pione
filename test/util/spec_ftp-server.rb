require 'pione/test-helper'

def make_temp_file(name, content)
  location = Location[Temppath.create]
  location.create(content)
  return location.path
end

shared "FTPFileSystem" do
  it "should exist" do
    @fs.should.exist(@dir_x)
    @fs.should.exist(@file_a)
    @fs.should.exist(@file_b)
    @fs.should.exist(@file_c)
  end

  it "should not exist" do
    @fs.should.not.exist(Pathname.new("/Y"))
  end

  it "should be directory" do
    @fs.should.directory(@dir_x)
  end

  it "should not be directory" do
    @fs.should.not.directory(@file_a)
    @fs.should.not.directory(@file_b)
    @fs.should.not.directory(@file_c)
  end

  it "should be file" do
    @fs.should.file(@file_a)
    @fs.should.file(@file_b)
    @fs.should.file(@file_c)
  end

  it "should not be file" do
    @fs.should.not.file(@dir_x)
  end

  it "should get file" do
    @fs.get_file(@file_a).should == "A"
    @fs.get_file(@file_b).should == "AB"
    @fs.get_file(@file_c).should == "ABC"
  end

  it "should put file" do
    file_d = @dir_x + "D"
    @fs.put_file(file_d, Tempfile.open("D"){|f| f.write "D"; f.path})
    @fs.should.exist(file_d)
  end

  it "should delete file" do
    @fs.delete_file(@file_a)
    @fs.should.not.exist(@file_a)
  end

  it "should get size" do
    @fs.get_size(@file_a).should == 1
    @fs.get_size(@file_b).should == 2
    @fs.get_size(@file_c).should == 3
  end

  it "should get mtime" do
    @fs.get_mtime(@file_a).should.kind_of(Time)
    @fs.get_mtime(@file_b).should.kind_of(Time)
    @fs.get_mtime(@file_c).should.kind_of(Time)
  end

  it "should get entries" do
    @fs.entries(@dir_x).should.include Pathname.new("A")
    @fs.entries(@dir_x).should.include Pathname.new("B")
    @fs.entries(@dir_x).should.include Pathname.new("C")
  end

  it "should make and delete directory" do
    dir_y = Pathname.new("/Y")
    @fs.mkdir(dir_y)
    @fs.should.directory(dir_y)
    @fs.rmdir(dir_y)
    @fs.should.not.exist(dir_y)
  end
end

describe "Pione::Util::FTPOnMemoryFS" do
  before do
    @fs = Util::FTPOnMemoryFS.new
    @dir_x = Pathname.new("/X")
    @file_a = @dir_x + "A"
    @file_b = @dir_x + "B"
    @file_c = @dir_x + "C"
    @fs.mkdir(@dir_x)
    @fs.put_file(@file_a, make_temp_file("A", "A"))
    @fs.put_file(@file_b, make_temp_file("B", "AB"))
    @fs.put_file(@file_c, make_temp_file("C", "ABC"))
  end

  behaves_like "FTPFileSystem"
end

describe "Pione::Util::FTPLocalFS" do
  before do
    location = Location[Temppath.create]
    location.path.mkdir
    @fs = Util::FTPLocalFS.new(location)
    @dir_x = Pathname.new("/X")
    @file_a = @dir_x + "A"
    @file_b = @dir_x + "B"
    @file_c = @dir_x + "C"
    @fs.mkdir(@dir_x)
    temp_a = Tempfile.new("A")
    temp_a.write "A"
    temp_a.close
    @fs.put_file(@file_a, make_temp_file("A", "A"))
    @fs.put_file(@file_b, make_temp_file("B", "AB"))
    @fs.put_file(@file_c, make_temp_file("C", "ABC"))
  end

  behaves_like "FTPFileSystem"
end

shared "FTPServer" do
  before do
    auth_info = Util::FTPServer.auth_info
    @ftp = Net::FTP.new
    @ftp.connect("localhost", Util::FTPServer.port)
    @ftp.login(auth_info.user, auth_info.password)
    @ftp.passive = true
  end

  after do
    @ftp.close
  end

  it "should authenticate" do
    @ftp.close
    @ftp.connect("localhost", Util::FTPServer.port)
    should.raise(Net::FTPPermError) do
      @ftp.login("A", "B")
    end
  end

  it "should change directory" do
    should.not.raise do
      @ftp.chdir("/X")
    end
  end

  it "should get files" do
    path = Temppath.create
    @ftp.get("/X/A", path)
    Location[path].read.should == "A"
    @ftp.get("/X/B", path)
    Location[path].read.should == "AB"
    @ftp.get("/X/C", path)
    Location[path].read.should == "ABC"
  end

  it "should put and delete file" do
    path = Temppath.create
    Location[path].create("D")
    @ftp.put(path, "/X/D")
    @ftp.get("/X/D", path)
    Location[path].read.should == "D"
    @ftp.delete("/X/D")
    should.raise(Net::FTPPermError) do
      @ftp.get("/X/D", path)
    end
  end

  it "should not put file" do
    path = Temppath.create
    Location[path].create("D")
    should.raise(Net::FTPPermError) do
      @ftp.put(path, "Z/D")
    end
  end

  it "should get mtime" do
    @ftp.mtime("/X/A").should.kind_of(Time)
    @ftp.mtime("/X/B").should.kind_of(Time)
    @ftp.mtime("/X/C").should.kind_of(Time)
  end

  it "should get list" do
    @ftp.list("/X").map{|line| line.split(" ").last}.tap do |x|
      x.should.include("A")
      x.should.include("B")
      x.should.include("C")
    end
  end

  it "should mkdir and rmdir" do
    @ftp.mkdir("/Y")
    @ftp.list("/Y")
    @ftp.rmdir("/Y")
    @ftp.list("/").map{|line| line.split(" ").last}.tap do |x|
      x.should.not.include("Y")
    end
  end

  it "should rename" do
    @ftp.rename("/X/A", "/A")
    @ftp.nlst("/").should.include("A")
    @ftp.nlst("/X").should.not.include("A")
    @ftp.rename("/A", "/X/A")
  end
end

describe "Pione::Util::FTPServer" do
  describe "on memory filesystem" do
    @fs = Util::FTPOnMemoryFS.new
    @dir_x = Pathname.new("/X")
    @file_a = @dir_x + "A"
    @file_b = @dir_x + "B"
    @file_c = @dir_x + "C"
    @fs.mkdir(@dir_x)
    @fs.put_file(@file_a, make_temp_file("A", "A"))
    @fs.put_file(@file_b, make_temp_file("B", "AB"))
    @fs.put_file(@file_c, make_temp_file("C", "ABC"))
    Util::FTPServer.stop
    sleep 0.1
    Util::FTPServer.start(@fs)
    sleep 0.1

    behaves_like "FTPServer"
  end

  describe "local file system" do
    location = Location[Temppath.create]
    location.path.mkdir
    @fs = Util::FTPLocalFS.new(location)
    @dir_x = Pathname.new("/X")
    @file_a = @dir_x + "A"
    @file_b = @dir_x + "B"
    @file_c = @dir_x + "C"
    @fs.mkdir(@dir_x)
    @fs.put_file(@file_a, make_temp_file("A", "A"))
    @fs.put_file(@file_b, make_temp_file("B", "AB"))
    @fs.put_file(@file_c, make_temp_file("C", "ABC"))
    Util::FTPServer.stop
    sleep 0.1
    Util::FTPServer.start(@fs)
    sleep 0.1

    behaves_like "FTPServer"
  end
end

