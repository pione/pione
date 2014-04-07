require 'pione/test-helper'

TestHelper.scope do |this|
  this::OUTPUT_REDUCTION_SIMPLE = Location[__FILE__].dirname + "data" + "OutputReduction_simple.pnml"

  describe Pione::PNML::Reader do
    it "should read a PNML file" do
      PNML::Reader.read(this::OUTPUT_REDUCTION_SIMPLE).tap do |net|
        net.should.kind_of PNML::Net
        net.places.size.should == 3
        net.transitions.size.should == 2
        net.arcs.size.should == 4
      end
    end
  end
end
