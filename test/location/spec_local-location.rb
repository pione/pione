require 'pione/test-helper'
require_relative 'location-behavior'

describe 'Location::LocalLocation' do
  before do
    @file = Location[Temppath.create]
    @dir = Location[Temppath.create]
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

  it "should be symbolic link" do
    desc = Location[Temppath.create].tap {|x| x.create("A")}
    @file.link(desc)
    @file.read.should == "A"
    @file.path.ftype.should == "link"
  end

  it 'should local copy' do
    dest = Location[Temppath.create]
    @file.create("A")
    @file.copy(dest)
    dest.read.should == "A"
    dest.path.ftype.should == "file"
    @file.read.should == "A"
    @file.path.ftype.should == "file"
  end

  it 'should local turn' do
    dest = Location[Temppath.create]
    @file.create("A")
    @file.turn(dest)
    dest.read.should == "A"
    dest.path.ftype.should == "file"
    @file.read.should == "A"
    @file.path.ftype.should == "link"
  end
end
