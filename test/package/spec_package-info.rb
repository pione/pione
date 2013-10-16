require 'pione/test-helper'

describe Pione::Package::PackageInfo do
  it "should dump as JSON and restore" do
    info = Package::PackageInfo.new(
      name: "P1",
      editor: "yamaguchi",
      tag: "test",
      parents: [Package::PackageInfo.new(name: "P2"), Package::PackageInfo.new(name: "P3")],
      documents: ["D1.pione", "D2.pione", "D3.pione"],
      scenarios: ["s1", "s2", "s3"]
    )
    _info = Package::PackageInfo.read(JSON.generate(info))
    _info.name.should == "P1"
    _info.editor.should == "yamaguchi"
    _info.tag.should == "test"
    _info.parents[0].name.should == "P2"
    _info.parents[1].name.should == "P3"
    _info.documents.should == ["D1.pione", "D2.pione", "D3.pione"]
    _info.scenarios.should == ["s1", "s2", "s3"]
  end
end
