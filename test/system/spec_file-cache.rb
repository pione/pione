require 'pione/test-helper'

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
    orig_location.path.ftype.should == "file"
  end

  it 'should put source into destination' do
    src = Location[Temppath.create].tap{|x| x.create("A")}
    dest = Location["http://example.com/abc"]
    System::FileCache.put(src, dest)
    cache = System::FileCache.get(dest)

    # check caching status
    dest.should.cached
    cache.read.should == src.read
  end

  it 'should cached' do
    orig = Location[Temppath.create].tap{|x| x.create("A")}
    System::FileCache.get(orig)
    orig.should.cached
  end
end

