require_relative '../test-util'

describe 'Location::LocalLocation' do
  before do
    @local = Location[Temppath.create]
  end

  after do
    @local.delete
  end

  it 'should create a file' do
    @local.create("A")
    @local.path.read.should == "A"
  end

  it 'should raise exception when the file exists already' do
    @local.create("A")
    should.raise(Location::ExistAlready) {@local.create("B")}
  end

  it 'should append data' do
    @local.create("A")
    @local.append("B")
    @local.read.should == "AB"
  end

  it "should not raise exception when the file doesn't exist" do
    @local.should.not.exist
    @local.append("A")
    @local.read.should == "A"
  end

  it 'should read a file' do
    @local.create("A")
    @local.read.should == "A"
  end

  it 'should update a file' do
    @local.create("A")
    @local.read.should == "A"
    @local.update("B")
    @local.read.should == "B"
    @local.update("C")
    @local.read.should == "C"
  end

  it 'should delete a file' do
    should.not.raise {@local.delete}
    @local.should.not.exist
    should.not.raise {@local.delete}
  end

  it 'should link' do
    desc = Location[Temppath.create].tap {|x| x.create("A")}
    @local.link(desc)
    @local.read.should == "A"
    @local.path.ftype.should == "link"
  end

  it 'should move' do
    dest = Location[Temppath.create]
    @local.create("A")
    @local.move(dest)
    dest.read.should == "A"
    dest.path.ftype.should == "file"
    @local.should.not.exist
  end

  it 'should copy' do
    dest = Location[Temppath.create]
    @local.create("A")
    @local.copy(dest)
    dest.read.should == "A"
    dest.path.ftype.should == "file"
    @local.read.should == "A"
    @local.path.ftype.should == "file"
  end

  it 'should turn' do
    dest = Location[Temppath.create]
    @local.create("A")
    @local.turn(dest)
    dest.read.should == "A"
    dest.path.ftype.should == "file"
    @local.read.should == "A"
    @local.path.ftype.should == "link"
  end

  it 'should get mtime information' do
    @local.create("A")
    @local.mtime.should.kind_of Time
  end

  it 'should get size information' do
    @local.create("A")
    @local.size.should == 1
  end
end
