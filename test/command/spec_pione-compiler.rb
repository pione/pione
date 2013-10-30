require 'pione/test-helper'

TestHelper.scope do |this|
  this::PNML1 = Location[File.dirname(__FILE__)] + "data" + "pione-compiler" + "Sequence.pnml"

  describe Pione::Command::PioneCompiler do
    it "should compile from PNML to PIONE document" do
      TestHelper::Command.succeed do
        Command::PioneCompiler.run [this::PNML1.path.to_s]
      end
    end

    it "should compile with package name" do
      res = TestHelper::Command.succeed do
        Command::PioneCompiler.run [this::PNML1.path.to_s, "--name", "Sequence"]
      end
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.not.include "@ Editor ::"
      res.stdout.string.should.not.include "@ Tag ::"
    end

    it "should compile with package name and editor" do
      res = TestHelper::Command.succeed do
        Command::PioneCompiler.run [this::PNML1.path.to_s, "--name", "Sequence", "--editor", "yamaguchi"]
      end
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.include "@ Editor :: \"yamaguchi\""
      res.stdout.string.should.not.include "@ Tag ::"
    end

    it "should compile with package name, editor, and tag" do
      res = TestHelper::Command.succeed do
        Command::PioneCompiler.run [this::PNML1.path.to_s, "--name", "Sequence", "--editor", "yamaguchi", "--tag", "test"]
      end
      res.stdout.string.should.include "@ PackageName :: \"Sequence\""
      res.stdout.string.should.include "@ Editor :: \"yamaguchi\""
      res.stdout.string.should.include "@ Tag :: \"test\""
    end
  end
end
