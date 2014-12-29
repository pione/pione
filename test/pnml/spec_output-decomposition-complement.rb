require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[__FILE__].dirname + "data"
  this::SIMPLE = this::DIR + "OutputDecompositionComplementSimple.pnml"
  this::COMPLEX = this::DIR + "OutputDecompositionComplementComplex.pnml"

  describe Pione::PNML::OutputDecompositionComplement do
    it "should complement the name of source place in simple case" do
      env = Lang::Environment.new
      net = PNML::Reader.read(this::SIMPLE)

      # elements
      transition_A = net.find_transition_by_name("A")
      place_RA = net.find_all_places_by_source_id(transition_A.id).first

      # apply "output decomposition complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::OutputDecompositionComplement}.rewrite(net, env)

      # test
      place_RA.name.should == ">'o1' or 'o2' or 'o3'"
    end

    it "should complement the name of source place in complex case" do
      env = Lang::Environment.new
      net = PNML::Reader.read(this::COMPLEX)

      # elements
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      place_RA = net.find_all_places_by_source_id(transition_A.id).first
      place_RB = net.find_all_places_by_source_id(transition_B.id).first

      # apply "output decomposition complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::OutputDecompositionComplement}.rewrite(net, env)

      # test
      place_RA.name.should == ">'o1' or 'o2' or 'o3'"
      place_RB.name.should == ">'o2' or 'o3' or 'o4'"
    end
  end
end
