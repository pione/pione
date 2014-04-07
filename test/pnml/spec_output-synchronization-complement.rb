require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[__FILE__].dirname + "data"
  this::SIMPLE = this::DIR + "OutputSynchronizationComplementSimple.pnml"
  this::COMPLEX = this::DIR + "OutputSynchronizationComplementComplex.pnml"

  describe Pione::PNML::OutputSynchronizationComplement do
    it "should name source place in simple case" do
      net = PNML::Reader.read(this::SIMPLE)

      # elements
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      transition_C = net.find_transition_by_name("C")
      place_RA = net.find_all_places_by_source_id(transition_A.id).first
      place_RB = net.find_all_places_by_source_id(transition_B.id).first
      place_RC = net.find_all_places_by_source_id(transition_C.id).first

      # apply "output synchronization complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::OutputSynchronizationComplement}.rewrite(net)

      # test
      place_RA.name.should == "'*.p1'"
      place_RB.name.should == "'*.p1'"
      place_RC.name.should == "'*.p1'"
    end

    it "should name source place in complex case" do
      net = PNML::Reader.read(this::COMPLEX)

      # elements
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      transition_C = net.find_transition_by_name("C")
      places_RA = net.find_all_places_by_source_id(transition_A.id)
      places_RB = net.find_all_places_by_source_id(transition_B.id)
      places_RC = net.find_all_places_by_source_id(transition_C.id)
      place_p1 = net.find_place_by_name("'*.p1'")
      place_p2 = net.find_place_by_name("'*.p2'")
      transition_Lp1 = net.find_transition_by_target_id(place_p1.id)
      transition_Lp2 = net.find_transition_by_target_id(place_p2.id)
      place_RA_p1 = places_RA.find {|place| net.find_arc(place.id, transition_Lp1.id)}
      place_RA_p2 = places_RA.find {|place| net.find_arc(place.id, transition_Lp2.id)}
      place_RB_p1 = places_RB.find {|place| net.find_arc(place.id, transition_Lp1.id)}
      place_RB_p2 = places_RB.find {|place| net.find_arc(place.id, transition_Lp2.id)}
      place_RC_p1 = places_RC.find {|place| net.find_arc(place.id, transition_Lp1.id)}
      place_RC_p2 = places_RC.find {|place| net.find_arc(place.id, transition_Lp2.id)}

      # apply "output synchronization complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::OutputSynchronizationComplement}.rewrite(net)

      # test
      place_RA_p1.name.should == "'*.p1'"
      place_RA_p2.name.should == "'*.p2'"
      place_RB_p1.name.should == "'*.p1'"
      place_RB_p2.name.should == "'*.p2'"
      place_RC_p1.name.should == "'*.p1'"
      place_RC_p2.name.should == "'*.p2'"
    end
  end
end
