require 'pione/test-helper'

describe Pione::Util::TaskDigest do
  it "should genereate task digest" do
    digest = Util::TaskDigest.generate("P", "R", [], Lang::ParameterSet.new)
    digest.should == "&P:R([],{})"
  end
end

describe Pione::Util::PackageDigest do
  it "should generate package digest" do
    location = Location[File.dirname(__FILE__)] + "data" + "HelloWorld+v0.1.0.ppg"
    Util::PackageDigest.generate(location).should == "e1869237e587c17134f5ecb9a7caf22c"
  end
end
