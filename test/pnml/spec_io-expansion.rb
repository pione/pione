require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[__FILE__].dirname + "data"
  this::SIMPLE = this::DIR + "IOExpansionSimple.pnml"
  this::COMPLEX = this::DIR + "IOExpansionComplex.pnml"

  describe Pione::PNML::IOExpansion do
    it "should expand in simple case" do
      env = Lang::Environment.new
      net = PNML::Reader.read(this::SIMPLE)

      # save elements
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      place_i1 = net.find_place_by_name("'i1'")
      place_p1 = net.find_place_by_name("'p1'")
      place_o1 = net.find_place_by_name(">'o1'")
      arc_A_p1 = net.find_arc(transition_A.id, place_p1.id)
      arc_p1_B = net.find_arc(place_p1.id, transition_B.id)

      # apply "input/output expansion"
      PNML::NetRewriter.new{|rules| rules << PNML::IOExpansion}.rewrite(net, env)

      # new elements
      places_p1= net.find_all_places_by_name("'p1'")
      places_p1.delete place_p1
      place_p1_expanded = places_p1.first
      accommodation = net.find_transition_by_source_id(place_p1.id)

      # test transitions
      net.transitions.size.should == 3
      net.transitions.should.include accommodation

      # test places
      net.places.size.should == 4
      net.places.should.include place_p1
      net.places.should.include place_p1_expanded

      # test arcs
      net.arcs.size.should == 6
      net.find_arc(place_p1.id, accommodation.id).should.not.nil
      net.find_arc(accommodation.id, place_p1_expanded.id).should.not.nil
      net.find_arc(place_p1_expanded.id, transition_B.id).should.not.nil
      net.arcs.should.include arc_A_p1
      net.arcs.should.not.include arc_p1_B
    end

    it "should expand in complex case" do
      env = Lang::Environment.new
      net = PNML::Reader.read(this::COMPLEX)

      # save elements
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      transition_C = net.find_transition_by_name("C")
      transition_D = net.find_transition_by_name("D")
      transition_E = net.find_transition_by_name("E")
      place_p1 = net.find_place_by_name("'p1'")
      place_p2 = net.find_place_by_name("'p2'")
      arc_A_p1 = net.find_arc(transition_A.id, place_p1.id)
      arc_B_p1 = net.find_arc(transition_B.id, place_p1.id)
      arc_p1_C = net.find_arc(place_p1.id, transition_C.id)
      arc_p1_D = net.find_arc(place_p1.id, transition_D.id)
      arc_p1_E = net.find_arc(place_p1.id, transition_E.id)
      arc_A_p2 = net.find_arc(transition_A.id, place_p2.id)
      arc_B_p2 = net.find_arc(transition_B.id, place_p2.id)
      arc_p2_C = net.find_arc(place_p2.id, transition_C.id)
      arc_p2_D = net.find_arc(place_p2.id, transition_D.id)
      arc_p2_E = net.find_arc(place_p2.id, transition_E.id)

      # apply "input/output expansion"
      PNML::NetRewriter.new{|rules| rules << PNML::IOExpansion}.rewrite(net, env)

      # test the net
      net.should.valid

      # new elements
      places_p1 = net.find_all_places_by_name("'p1'")
      places_p1.delete place_p1
      place_p1_expanded = places_p1.first
      places_p2 = net.find_all_places_by_name("'p2'")
      places_p2.delete place_p2
      place_p2_expanded = places_p2.first
      accommodation_p1 = net.find_transition_by_source_id(place_p1.id)
      accommodation_p2 = net.find_transition_by_source_id(place_p2.id)

      # test transitions
      net.transitions.size.should == 7
      net.transitions.should.include accommodation_p1
      net.transitions.should.include accommodation_p2

      # test places
      net.places.size.should == 9
      net.places.should.include place_p1
      net.places.should.include place_p1_expanded
      net.places.should.include place_p2
      net.places.should.include place_p2_expanded

      # test arcs
      net.arcs.size.should == 19
      net.find_arc(place_p1.id, accommodation_p1.id).should.not.nil
      net.find_arc(accommodation_p1.id, place_p1_expanded.id).should.not.nil
      net.find_arc(place_p1_expanded.id, transition_C.id).should.not.nil
      net.find_arc(place_p1_expanded.id, transition_D.id).should.not.nil
      net.find_arc(place_p1_expanded.id, transition_E.id).should.not.nil
      net.find_arc(place_p2.id, accommodation_p2.id).size.should.not.nil
      net.find_arc(accommodation_p2.id, place_p2_expanded.id).should.not.nil
      net.find_arc(place_p2_expanded.id, transition_C.id).should.not.nil
      net.find_arc(place_p2_expanded.id, transition_D.id).should.not.nil
      net.find_arc(place_p2_expanded.id, transition_E.id).should.not.nil
      net.arcs.should.include arc_A_p1
      net.arcs.should.include arc_B_p1
      net.arcs.should.include arc_A_p2
      net.arcs.should.include arc_B_p2
      net.arcs.should.not.include arc_p1_C
      net.arcs.should.not.include arc_p1_D
      net.arcs.should.not.include arc_p1_E
      net.arcs.should.not.include arc_p2_C
      net.arcs.should.not.include arc_p2_D
      net.arcs.should.not.include arc_p2_E
      net.find_arc(place_p1.id, accommodation_p2.id).should.nil
      net.find_arc(place_p2.id, accommodation_p1.id).should.nil
      net.find_arc(accommodation_p1.id, place_p2_expanded).should.nil
      net.find_arc(accommodation_p2.id, place_p1_expanded).should.nil
    end
  end
end
