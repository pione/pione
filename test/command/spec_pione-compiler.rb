require 'pione/test-helper'

TestHelper.scope do |this|
  this::PNML1 = Location[File.dirname(__FILE__)] + "data" + "pione-compiler" + "Sequence.pnml"

  describe Pione::Command::PioneCompiler do
    before do
      @cmd = Pione::Command::PioneCompiler
    end

    it "should compile from PNML to PIONE document" do
      TestHelper::Command.succeed(@cmd, [this::PNML1.path.to_s])
    end

    it "should compile with package name" do
      res = TestHelper::Command.succeed(@cmd, [this::PNML1.path.to_s, "--name", "Sequence"])
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.not.include "@ Editor ::"
      res.stdout.string.should.not.include "@ Tag ::"
    end

    it "should compile with package name and editor" do
      args = [this::PNML1.path.to_s, "--name", "Sequence", "--editor", "yamaguchi"]
      res = TestHelper::Command.succeed(@cmd, args)
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.include "@ Editor :: \"yamaguchi\""
      res.stdout.string.should.not.include "@ Tag ::"
    end

    it "should compile with package name, editor, and tag" do
      args = [this::PNML1.path.to_s, "--name", "Sequence", "--editor", "yamaguchi", "--tag", "test"]
      res = TestHelper::Command.succeed(@cmd, args)
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.include "@ Editor :: \"yamaguchi\""
      res.stdout.string.should.include "@ Tag :: \"test\""
    end
  end
end
