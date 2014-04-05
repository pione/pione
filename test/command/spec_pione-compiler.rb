require 'pione/test-helper'

TestHelper.scope do |this|
  this::PNML1 = Location[File.dirname(__FILE__)] + "data" + "pione-compiler" + "Sequence.pnml"

  describe Pione::Command::PioneCompiler do
    before do
      @cmd = Pione::Command::PioneCompiler
    end

    it "should compile from PNML to PIONE document" do
      Rootage::ScenarioTest.succeed(@cmd.new([this::PNML1.path.to_s]))
    end

    it "should compile with package name" do
      res = Rootage::ScenarioTest.succeed(@cmd.new([this::PNML1.path.to_s, "--name", "Sequence"]))
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.not.include "@ Editor ::"
      res.stdout.string.should.not.include "@ Tag ::"
    end

    it "should compile with package name and editor" do
      cmd = @cmd.new([this::PNML1.path.to_s, "--name", "Sequence", "--editor", "yamaguchi"])
      res = Rootage::ScenarioTest.succeed(cmd)
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.include "@ Editor :: \"yamaguchi\""
      res.stdout.string.should.not.include "@ Tag ::"
    end

    it "should compile with package name, editor, and tag" do
      cmd = @cmd.new([this::PNML1.path.to_s, "--name", "Sequence", "--editor", "yamaguchi", "--tag", "test"])
      res = Rootage::ScenarioTest.succeed(cmd)
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.include "@ Editor :: \"yamaguchi\""
      res.stdout.string.should.include "@ Tag :: \"test\""
    end
  end
end
