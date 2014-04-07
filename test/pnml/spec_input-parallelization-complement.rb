require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[__FILE__].dirname + "data"
  this::SIMPLE = this::DIR + "InputParallelizationComplementSimple.pnml"
  this::COMPLEX = this::DIR + "InputParallelizationComplementComplex.pnml"

  describe Pione::PNML::InputParallelizationComplement do
    it "should name by `input parallelization` in simple case" do
      net = PNML::Reader.read(this::SIMPLE)

      # elements
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      transition_C = net.find_transition_by_name("C")
      place_LA = net.find_all_places_by_target_id(transition_A.id).first
      place_LB = net.find_all_places_by_target_id(transition_B.id).first
      place_LC = net.find_all_places_by_target_id(transition_C.id).first

      # apply "input parallelization complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::InputParallelizationComplement}.rewrite(net)

      # test
      place_LA.name.should == "'i1'"
      place_LB.name.should == "'i1'"
      place_LC.name.should == "'i1'"
    end

    it "should name by `input parallelization` in complex case" do
      net = PNML::Reader.read(this::COMPLEX)

      # elements
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      transition_C = net.find_transition_by_name("C")
      places_LA = net.find_all_places_by_target_id(transition_A.id)
      places_LB = net.find_all_places_by_target_id(transition_B.id)
      places_LC = net.find_all_places_by_target_id(transition_C.id)

      # apply "input parallelization complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::InputParallelizationComplement}.rewrite(net)

      # test
      places_LA.map{|place| place.name}.sort.should == ["'i1'", "'i2'"]
      places_LB.map{|place| place.name}.sort.should == ["'i1'", "'i2'"]
      places_LC.map{|place| place.name}.sort.should == ["'i1'", "'i2'"]
    end
  end
end

