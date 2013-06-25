shared "location" do
  it 'should create a file' do
    @file.create("A")
    @file.read.should == "A"
  end

  it 'should raise exception when the file exists already' do
    @file.create("A")
    should.raise(Location::ExistAlready) {@file.create("B")}
  end

  it 'should append data' do
    @file.create("A")
    @file.append("B")
    @file.read.should == "AB"
  end

  it "should not raise exception when the file doesn't exist" do
    @file.should.not.exist
    @file.append("A")
    @file.read.should == "A"
  end

  it 'should read a file' do
    @file.create("A")
    @file.read.should == "A"
  end

  it 'should update a file' do
    @file.create("A")
    @file.read.should == "A"
    @file.update("B")
    @file.read.should == "B"
    @file.update("C")
    @file.read.should == "C"
  end

  it 'should delete a file' do
    should.not.raise {@file.delete}
    @file.should.not.exist
    should.not.raise {@file.delete}
  end

  it 'should link' do
    desc = Location[Temppath.create].tap {|x| x.create("A")}
    @file.link(desc)
    @file.read.should == "A"
  end

  it 'should move' do
    dest = Location[Temppath.create]
    @file.create("A")
    @file.move(dest)
    dest.read.should == "A"
    dest.path.ftype.should == "file"
    @file.should.not.exist
  end

  it 'should copy' do
    dest = Location[Temppath.create]
    @file.create("A")
    @file.copy(dest)
    dest.read.should == "A"
    @file.read.should == "A"
  end

  it 'should turn' do
    dest = Location[Temppath.create]
    @file.create("A")
    @file.turn(dest)
    dest.read.should == "A"
    @file.read.should == "A"
  end

  it 'should get mtime information' do
    @file.create("A")
    @file.mtime.should.kind_of Time
  end

  it 'should get size information' do
    @file.create("A")
    @file.size.should == 1
  end

  it 'should get entries' do
    @dir.entries.size.should == 4
    @dir.entries.should.include(@dir + "A")
    @dir.entries.should.include(@dir + "B")
    @dir.entries.should.include(@dir + "C")
    @dir.entries.should.include(@dir + "D")
    @dir.entries.should.not.include(@dir + ".")
    @dir.entries.should.not.include(@dir + "..")
    @dir.entries.should.not.include(@dir + "X")
    @dir.entries.should.not.include(@dir + "Y")
    @dir.entries.should.not.include(@dir + "Z")
    (@dir + "D").entries.size.should == 3
    (@dir + "D").entries.should.include(@dir + "D" + "X")
    (@dir + "D").entries.should.include(@dir + "D" + "Y")
    (@dir + "D").entries.should.include(@dir + "D" + "Z")
  end

  it 'should get file entries' do
    @dir.file_entries.size.should == 3
    @dir.file_entries.should.include(@dir + "A")
    @dir.file_entries.should.include(@dir + "B")
    @dir.file_entries.should.include(@dir + "C")
    @dir.file_entries.should.not.include(@dir + "D")
    (@dir + "D").file_entries.size.should == 3
    (@dir + "D").file_entries.should.include(@dir + "D" + "X")
    (@dir + "D").file_entries.should.include(@dir + "D" + "Y")
    (@dir + "D").file_entries.should.include(@dir + "D" + "Z")
  end

  it 'should get directory entries' do
    @dir.directory_entries.size.should == 1
    @dir.directory_entries.should.not.include(@dir + "A")
    @dir.directory_entries.should.not.include(@dir + "B")
    @dir.directory_entries.should.not.include(@dir + "C")
    @dir.directory_entries.should.include(@dir + "D")
    (@dir + "D").directory_entries.size.should == 0
    (@dir + "D").directory_entries.should.not.include(@dir + "D" + "X")
    (@dir + "D").directory_entries.should.not.include(@dir + "D" + "Y")
    (@dir + "D").directory_entries.should.not.include(@dir + "D" + "Z")
  end

  it "should get local location" do
    @file.create("A")
    local = @file.local
    local.scheme.should == "local"
    local.should.exist
    local.should.file
  end
end
