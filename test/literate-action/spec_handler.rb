require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data"
  this::D1 = this::DIR + "D1.md"

  describe Pione::LiterateAction::Handler do
    def get_action(md, name, expected)
      doc = LiterateAction::Document.load(md)
      doc.find(name).tap do |handler|
        handler.textize(nil).chomp.should == expected
      end
    end

    def execute_action(md, name, expected)
      doc = LiterateAction::Document.load(md)
      doc.find(name).tap do |handler|
        out = Location[Temppath.create]
        handler.execute(:out => out)
        out.read.chomp.should == expected
      end
    end

    it "should get a text" do
      get_action(this::D1, "Name1", "echo A")
      get_action(this::D1, "Name2", "puts \"A\"\nputs \"B\"")
    end

    it "should execute" do
      execute_action(this::D1, "Name1", "A")
      execute_action(this::D1, "Name2", "A\nB")
    end
  end
end
