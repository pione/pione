require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + "data" + "pione-list-param"

  describe Pione::Command::PioneListParam do
    it "should show basic parameters" do
      args = [(this::DIR + "BasicParameters.pione").path.to_s]
      res = TestHelper::Command.succeed do
        Command::PioneListParam.run(args)
      end
      out = res.stdout.string
      out.should.include "B1"
      out.should.include "B2"
      out.should.include "B3"
      out.should.include "I1"
      out.should.include "I2"
      out.should.include "S1"
      out.should.include "S2"
      out.should.include "D1"
      out.should.include "D2"
    end

    it "should show basic parameters only without `--advanced` option" do
      args = [(this::DIR + "AdvancedParameters.pione").path.to_s]
      res = TestHelper::Command.succeed do
        Command::PioneListParam.run(args)
      end
      out = res.stdout.string
      out.should.include "B1"
      out.should.not.include "B2"
      out.should.not.include "B3"
      out.should.include "I1"
      out.should.not.include "I2"
      out.should.include "S1"
      out.should.not.include "S2"
      out.should.include "D1"
      out.should.not.include "D2"
    end

    it "should show advanced parameters with `--advanced` option" do
      args = [(this::DIR + "AdvancedParameters.pione").path.to_s, "--advanced"]
      res = TestHelper::Command.succeed do
        Command::PioneListParam.run(args)
      end
      out = res.stdout.string
      out.should.include "B1"
      out.should.include "B2"
      out.should.include "B3"
      out.should.include "I1"
      out.should.include "I2"
      out.should.include "S1"
      out.should.include "S2"
      out.should.include "D1"
      out.should.include "D2"
    end
  end
end
