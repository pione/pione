require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data"
  this::D1 = this::DIR + "D1.md"

  describe Pione::LiterateAction::Document do
    it "should get action names" do
      doc = LiterateAction::Document.load(this::D1)
      doc.action_names.sort.should == ["Name1", "Name2"]
    end

    it "should get action handler by name" do
      doc = LiterateAction::Document.load(this::D1)
      doc.find("Name1").should.kind_of LiterateAction::Handler
      doc.find("Name2").should.kind_of LiterateAction::Handler
      doc.find("Name3").should.nil
    end
  end
end
