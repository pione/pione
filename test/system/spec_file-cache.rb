require_relative '../test-util'

describe 'System::FileCache' do
  before do
    System::FileCache.clear
  end

  it 'shoud get cached file path' do
    orig_location = Location[Temppath.create].tap{|x| x.create("A")}
    cache_location = System::FileCache.get(orig_location)
    orig_location.should.exist
    cache_location.should.exist
    cache_location.read.should == "A"
    cache_location.path.ftype.should == "file"
    orig_location.read.should == "A"
    orig_location.path.ftype.should == "link"
  end

  it 'should put source into destination' do
    src = Location[Temppath.create].tap{|x| x.create("A")}
    dest = Location[Temppath.create]
    System::FileCache.put(src, dest)
    src.should.cached
    dest.should.cached
    System::FileCache.get(src).read.should == "A"
    System::FileCache.get(dest).read.should == "A"
    System::FileCache.get(src).should == System::FileCache.get(dest)
    src.path.ftype == "link"
    dest.path.ftype == "file"
    System::FileCache.get(src).path.ftype == "link"
  end

  it 'should cached' do
    orig = Location[Temppath.create].tap{|x| x.create("A")}
    System::FileCache.get(orig)
    orig.should.cached
  end
end

