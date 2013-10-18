require 'pione/test-helper'

describe Pione::Util::TaskDigest do
  it "should genereate task digest" do
    digest = Util::TaskDigest.generate("P", "R", [], Lang::ParameterSet.new)
    digest.should == "&P:R([],{})"
  end
end

describe Pione::Util::PackageDigest do
  it "should generate package digest" do
    location = Location[File.dirname(__FILE__)] + "data" + "HelloWorld+v0.1.1.ppg"
    Util::PackageDigest.generate(location).should == "699c478eb7ce00fa00743a30f999f245"
  end
end
