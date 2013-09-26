require 'pione/test-helper'

shared "package filename" do
  it "should parse the package filename" do
    Component::PackageFilename.parse(@filename).tap do |fname|
      fname.package_name.should == @package_name
      fname.edition.should == @edition
      fname.tag.should == @tag
      fname.hash_id.should == @hash_id
    end
  end

  it "should build package filename string" do
    Component::PackageFilename.parse(@filename).to_s.should == @filename
  end
end

describe "Pione::Component::PackageFilename" do
  describe "package name + edition + tag + hash_id" do
    before do
      @filename = "Test(keita.yamaguchi@gmail.com)+test@d462c59.ppg"
      @package_name = "Test"
      @edition = "keita.yamaguchi@gmail.com"
      @tag = "test"
      @hash_id = "d462c59"
    end

    behaves_like "package filename"
  end

  describe "package name + 'origin' + tag + hash_id" do
    before do
      @filename = "Test+test@d462c59.ppg"
      @package_name = "Test"
      @edition = "origin"
      @tag = "test"
      @hash_id = "d462c59"
    end

    behaves_like "package filename"
  end

  describe "package name + tag + hash_id" do
    before do
      @filename = "Test+test@d462c59.ppg"
      @package_name = "Test"
      @edition = "origin"
      @tag = "test"
      @hash_id = "d462c59"
    end

    behaves_like "package filename"
  end

  describe "package name + tag" do
    before do
      @filename = "Test+test.ppg"
      @package_name = "Test"
      @edition = "origin"
      @tag = "test"
      @hash_id = nil
    end

    behaves_like "package filename"
  end

  describe "package name + hash id" do
    before do
      @filename = "Test@d462c59.ppg"
      @package_name = "Test"
      @edition = "origin"
      @tag = nil
      @hash_id = "d462c59"
    end

    behaves_like "package filename"
  end
end

