require 'pione/test-helper'

TestHelper.scope do |this|
  this::DOC = Location[__FILE__].dirname + "data" + "IsolatedElementElimination.pnml"

  describe Pione::PNML::IsolatedElementElimination do
    it "should elminate floating elements" do
      env = Lang::Environment.new
      net = PNML::Reader.read(this::DOC)

      # apply floating element elimination
      PNML::NetRewriter.new{|rules| rules << PNML::IsolatedElementElimination}.rewrite(net, env)

      # test
      net.find_transition_by_name("A").should.not.nil
      net.find_transition_by_name("B").should.nil
      net.find_transition_by_name("C").should.nil
      net.find_place_by_name("<'i1'").should.not.nil
      net.find_place_by_name("'i2'").should.nil
      net.find_place_by_name("'i3'").should.nil
      net.find_place_by_name("'i4'").should.nil
      net.find_place_by_name("'i5'").should.nil
      net.find_place_by_name(">'o1'").should.not.nil
    end
  end
end
