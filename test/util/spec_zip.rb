require 'pione/test-helper'

shared "archiver" do
  it "should compress and uncompress" do
    Util::Zip.compress(@src, @archive)
    @archive.should.exist
    @archive.size.should > 0
    Util::Zip.uncompress(@archive, @dest)
    (@dest + "A").read.should == "A"
    (@dest + "B").read.should == "B"
    (@dest + "C/1").read.should == "C"
    (@dest + "D/2").read.should == "D"
    (@dest+ "E/1/2").read.should == "E"
  end
end

describe "Pione::Util::Zip" do
  def create_files(src)
    (src + "A").create("A")
    (src + "B").create("B")
    (src + "C/1").create("C")
    (src + "D/2").create("D")
    (src + "E/1/2").create("E")
  end

  describe "local -> local -> local" do
    before do
      @src = Location[Temppath.mkdir]
      create_files(@src)
      @archive = Location[Temppath.create]
      @dest = Location[Temppath.mkdir]
    end

    behaves_like "archiver"
  end
end
