require 'pione/test-helper'

describe "Pione::Location::GitScheme" do
  before do
    @uri = URI.parse("git://github.com/pione/pione.git")
  end

  it "should get host" do
    @uri.host.should == "github.com"
  end

  it "should get scheme" do
    @uri.scheme.should == "git"
  end

  it "should get path" do
    @uri.path.should == "/pione/pione.git"
  end
end

