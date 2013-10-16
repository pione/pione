require 'pione/test-helper'

describe Pione::Package::Database do
  before do
    @db_location = Location[Temppath.create]
    @db = Package::Database.new
    @db.add(name: "P1", edition: "origin", type: "ppg", digest: "d1")
    @db.add(name: "P1", edition: "origin", tag: "test", type: "ppg", digest: "d2")
    @db.add(name: "P1", edition: "yamaguchi", type: "ppg", digest: "d3")
    @db.add(name: "P2", edition: "origin", type: "ppg", digest: "d4")
    @db.add(name: "P2", edition: "origin", tag: "v0.1.0", type: "git", location: "git://example.com/repo", digest: "d4")
    @db.add(name: "P2", edition: "origin", tag: "v0.1.1", type: "dir", location: "local://home/keita/repo", digest: "d5")
  end

  it "should have records in database" do
    @db.count.should == 6
  end

  it "should get package digests" do
    @db.find("P1", nil, nil).digest.should == "d1"
    @db.find("P1", nil, "test").digest.should == "d2"
    @db.find("P1", "yamaguchi", nil).digest.should == "d3"
    @db.find("P1", "yamaguchi", "test").should.nil
    @db.find("P2", nil, nil).digest.should == "d4"
    @db.find("P2", nil, "v0.1.0").digest.should == "d4"
    @db.find("P2", nil, "v0.1.1").digest.should == "d5"
  end

  it "should save the package database" do
    @db_location.should.not.exist
    @db.save(@db_location)
    @db_location.should.exist
    db = Package::Database.load(@db_location)
    db.find("P1", nil, nil).digest.should == "d1"
    db.find("P1", nil, "test").digest.should == "d2"
    db.find("P1", "yamaguchi", nil).digest.should == "d3"
    db.find("P1", "yamaguchi", "test").should.nil
    db.find("P2", nil, nil).digest.should == "d4"
    db.find("P2", nil, "v0.1.0").digest.should == "d4"
    db.find("P2", nil, "v0.1.1").digest.should == "d5"
  end
end
