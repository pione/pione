require 'pione/test-helper'

TestHelper.scope do |this|
  this::PNML1 = Location[File.dirname(__FILE__)] + "data" + "pione-compiler" + "Sequence.pnml"

  describe Pione::Command::PioneCompiler do
    it "should compile from PNML to PIONE document" do
      res = TestHelper::Command.succeed do
        Command::PioneCompiler.run [this::PNML1.path.to_s]
      end
    end
  end
end
