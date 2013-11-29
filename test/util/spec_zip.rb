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

describe Pione::Util::Zip do
  describe "base" do
    before do
      @src = Location[Temppath.mkdir]
      @archive = Location[Temppath.create]
      @dest = Location[Temppath.mkdir]
    end

    it "should archive excepting broken links" do
      # make a broken link
      (@src + "a").create("A")
      (@src + "b").create("B")
      (@src + "c").link(@src + "b")
      (@src + "b").delete

      # compress and uncompress
      Util::Zip.compress(@src, @archive)
      Util::Zip.uncompress(@archive, @dest)

      # test
      @archive.should.exist
      @dest.entries.size.should == 1
      (@dest + "a").should.exist
      (@dest + "b").should.not.exist
      (@dest + "c").should.not.exist
    end
  end

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
