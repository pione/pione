require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data"
  this::D1 = this::DIR + "D1.md"

  describe Pione::LiterateAction::Handler do
    it "should get a text" do
      doc = LiterateAction::Document.load(this::D1)
      doc.find("Name1").tap do |handler|
        handler.textize(nil).chomp.should == "echo A"
      end
      doc.find("Name2").tap do |handler|
        handler.textize(nil).chomp.should == "puts \"A\"\nputs \"B\""
      end
    end

    it "should execute" do
      doc = LiterateAction::Document.load(this::D1)
      doc.find("Name1").tap do |handler|
        handler.execute(nil).chomp.should == "A"
      end
      doc.find("Name2").tap do |handler|
        handler.execute(nil).chomp.should == "A\nB"
      end
    end
  end
end
