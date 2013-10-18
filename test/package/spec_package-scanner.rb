require 'pione/test-helper'

TestHelper.scope do |this|
  # simple package
  this::P1 = Location[File.dirname(__FILE__)] + "data" + "PackageScannerP1"

  # package with single inheritance
  this::P2 = Location[File.dirname(__FILE__)] + "data" + "PackageScannerP2"

  # package with multiple inheritance
  this::P3 = Location[File.dirname(__FILE__)] + "data" + "PackageScannerP3"

  # package that has multiple documents
  this::P4 = Location[File.dirname(__FILE__)] + "data" + "PackageScannerP4"

  # package that has multiple scenarios
  this::P5 = Location[File.dirname(__FILE__)] + "data" + "PackageScannerP5"

  describe Pione::Package::PackageScanner do
    it "should scan package informations" do
      p1 = Package::PackageScanner.new(this::P1).scan
      p1.name.should == "P1"
      p1.editor.should == "yamaguchi"
      p1.tag.should == "test"
      p1.parents.should.empty
    end

    it "should scan parents" do
      p2 = Package::PackageScanner.new(this::P2).scan
      p2.name.should == "P2"
      p2.editor.should.nil
      p2.tag.should.nil
      p2.parents.size.should == 1
      p2.parents.should.include Package::ParentPackageInfo.new(name: "P1", editor: "yamaguchi", tag: "test")
      p3 = Package::PackageScanner.new(this::P3).scan
      p3.name.should == "P3"
      p3.editor.should.nil
      p3.tag.should.nil
      p3.parents.size.should == 2
      p3.parents.should.include Package::ParentPackageInfo.new(name: "P1", editor: "yamaguchi", tag: "test")
      p3.parents.should.include Package::ParentPackageInfo.new(name: "P2")
    end

    it "should scan documents" do
      p4 = Package::PackageScanner.new(this::P4).scan
      p4.name.should == "P4"
      p4.documents.should.include "Doc1.pione"
      p4.documents.should.include "Doc2.pione"
      p4.documents.should.include "Doc3.pione"
      p4.documents.should.include "sub1/Doc4.pione"
      p4.documents.should.include "sub1/sub1-1/Doc5.pione"
      p4.documents.should.include "sub2/sub2-1/sub2-1-1/Doc6.pione"
      p4.documents.should.include "sub2/sub2-1/sub2-1-2/Doc7.pione"
    end

    it "should scan scenario" do
      p5 = Package::PackageScanner.new(this::P5).scan
      p5.name.should == "P5"
      p5.scenarios.should.include "scenario1"
      p5.scenarios.should.include "scenario2"
      p5.scenarios.should.include "scenario3"
      p5.scenarios.should.include "sub1/scenario4"
      p5.scenarios.should.include "sub1/sub1-1/scenario5"
      p5.scenarios.should.include "sub2/sub2-1/sub2-1-1/scenario6"
      p5.scenarios.should.include "sub2/sub2-1/sub2-1-2/scenario7"
    end
  end
end
