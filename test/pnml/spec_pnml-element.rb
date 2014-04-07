require 'pione/test-helper'

TestHelper.scope do |this|
  this::SAMPLE_NET = Location[__FILE__].dirname + "data" + "SampleNet.pnml"

  describe Pione::PNML::Net do
    before do
      @net = PNML::Reader.read(this::SAMPLE_NET)
      @transition_A = @net.find_transition_by_name("A")
      @transition_B = @net.find_transition_by_name("B")
      @place_i1 = @net.find_place_by_name("'i1'")
      @place_i2 = @net.find_place_by_name("'i2'")
      @place_i3 = @net.find_place_by_name("'i3'")
      @place_p1 = @net.find_place_by_name("'p1'")
      @place_o1 = @net.find_place_by_name(">'o1'")
      @place_o2 = @net.find_place_by_name(">'o2'")
      @place_o3 = @net.find_place_by_name(">'o3'")
      @arc_i1_A = @net.find_arc(@place_i1.id, @transition_A.id)
      @arc_i2_A = @net.find_arc(@place_i2.id, @transition_A.id)
      @arc_i3_A = @net.find_arc(@place_i3.id, @transition_A.id)
      @arc_A_p1 = @net.find_arc(@transition_A.id, @place_p1.id)
      @arc_p1_B = @net.find_arc(@place_p1.id, @transition_B.id)
      @arc_B_o1 = @net.find_arc(@transition_B.id, @place_o1.id)
      @arc_B_o2 = @net.find_arc(@transition_B.id, @place_o2.id)
      @arc_B_o3 = @net.find_arc(@transition_B.id, @place_o3.id)
    end

    it "should have palces" do
      @net.places.size.should == 7
      @net.places.each {|place| place.should.kind_of PNML::Place}
    end

    it "should have transitions" do
      @net.transitions.size.should == 2
      @net.transitions.each {|transition| transition.should.kind_of PNML::Transition}
    end

    it "should have arcs" do
      @net.arcs.size.should == 8
      @net.arcs.each {|arc| arc.should.kind_of PNML::Arc}
    end

    it "should generate a new ID" do
      ids = (@net.places + @net.transitions + @net.arcs).map {|elt| elt.id}
      ids.should.not.include @net.generate_id
    end

    it "should find an arc by source ID and target ID" do
      arc = @net.arcs.first
      @net.find_arc(arc.source_id, arc.target_id).should == arc
      @net.find_arc(Util::UUID.generate, Util::UUID.generate).should.nil
    end

    it "should find all arcs by source ID" do
      @net.find_all_arcs_by_source_id(@place_i1.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_i1_A
      end

      @net.find_all_arcs_by_source_id(@place_i2.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_i2_A
      end

      @net.find_all_arcs_by_source_id(@place_i3.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_i3_A
      end

      @net.find_all_arcs_by_source_id(@transition_A.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_A_p1
      end

      @net.find_all_arcs_by_source_id(@place_p1.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_p1_B
      end

      @net.find_all_arcs_by_source_id(@transition_B.id).tap do |arcs|
        arcs.size.should == 3
        arcs.should.include @arc_B_o1
        arcs.should.include @arc_B_o2
        arcs.should.include @arc_B_o3
      end

      @net.find_all_arcs_by_source_id(@place_o1.id).size.should == 0
      @net.find_all_arcs_by_source_id(@place_o2.id).size.should == 0
      @net.find_all_arcs_by_source_id(@place_o3.id).size.should == 0
    end

    it "should find all arcs by target ID" do
      @net.find_all_arcs_by_target_id(@place_i1.id).size.should == 0
      @net.find_all_arcs_by_target_id(@place_i2.id).size.should == 0
      @net.find_all_arcs_by_target_id(@place_i3.id).size.should == 0

      @net.find_all_arcs_by_target_id(@transition_A.id).tap do |arcs|
        arcs.size.should == 3
        arcs.should.include @arc_i1_A
        arcs.should.include @arc_i2_A
        arcs.should.include @arc_i3_A
      end

      @net.find_all_arcs_by_target_id(@place_p1.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_A_p1
      end

      @net.find_all_arcs_by_target_id(@transition_B.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_p1_B
      end

      @net.find_all_arcs_by_target_id(@place_o1.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_B_o1
      end

      @net.find_all_arcs_by_target_id(@place_o2.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_B_o2
      end

      @net.find_all_arcs_by_target_id(@place_o3.id).tap do |arcs|
        arcs.size.should == 1
        arcs.should.include @arc_B_o3
      end
    end

    it "should get arcs from transtion to place" do
      @net.tp_arcs.tap do |arcs|
        arcs.size.should == 4
        arcs.should.include @arc_A_p1
        arcs.should.include @arc_B_o1
        arcs.should.include @arc_B_o2
        arcs.should.include @arc_B_o3
      end
    end

    it "should get arcs from place to transtion" do
      @net.pt_arcs.tap do |arcs|
        arcs.size.should == 4
        arcs.should.include @arc_i1_A
        arcs.should.include @arc_i2_A
        arcs.should.include @arc_i3_A
        arcs.should.include @arc_p1_B
      end
    end

    it "should find a transition by ID" do
      @net.find_transition(@transition_A.id).should == @transition_A
      @net.find_transition(@transition_B.id).should == @transition_B
      @net.find_transition(Util::UUID.generate).should.nil
    end

    it "should find a transition by name" do
      @net.find_transition_by_name("A").should == @transition_A
      @net.find_transition_by_name("B").should == @transition_B
      @net.find_transition_by_name("C").should.nil
    end

    it "should find all transitions by name" do
      @net.find_all_transitions_by_name("A").should == [@transition_A]
      @net.find_all_transitions_by_name("B").should == [@transition_B]
      @net.find_all_transitions_by_name("C").should.empty
    end

    it "should find all tarnsitions by source ID" do
      @net.find_all_transitions_by_source_id(@place_i1.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_A
      end

      @net.find_all_transitions_by_source_id(@place_i2.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_A
      end

      @net.find_all_transitions_by_source_id(@place_i3.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_A
      end

      @net.find_all_transitions_by_source_id(@place_p1.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_B
      end

      @net.find_all_transitions_by_source_id(@place_o1.id).should.empty
      @net.find_all_transitions_by_source_id(@place_o2.id).should.empty
      @net.find_all_transitions_by_source_id(@place_o3.id).should.empty
    end

    it "should find all transitions by target ID" do
      @net.find_all_transitions_by_target_id(@place_i1.id).should.empty
      @net.find_all_transitions_by_target_id(@place_i2.id).should.empty
      @net.find_all_transitions_by_target_id(@place_i3.id).should.empty

      @net.find_all_transitions_by_target_id(@place_p1.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_A
      end

      @net.find_all_transitions_by_target_id(@place_o1.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_B
      end

      @net.find_all_transitions_by_target_id(@place_o2.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_B
      end

      @net.find_all_transitions_by_target_id(@place_o3.id).tap do |transitions|
        transitions.size.should == 1
        transitions.should.include @transition_B
      end
    end

    it "should find a place by ID" do
      @net.find_place(@place_i1.id).should == @place_i1
      @net.find_place(@place_i2.id).should == @place_i2
      @net.find_place(@place_i3.id).should == @place_i3
      @net.find_place(@place_p1.id).should == @place_p1
      @net.find_place(@place_o1.id).should == @place_o1
      @net.find_place(@place_o2.id).should == @place_o2
      @net.find_place(@place_o3.id).should == @place_o3
    end

    it "should find a place by name" do
      @net.find_place_by_name("'i1'").should == @place_i1
      @net.find_place_by_name("'i2'").should == @place_i2
      @net.find_place_by_name("'i3'").should == @place_i3
      @net.find_place_by_name("'p1'").should == @place_p1
      @net.find_place_by_name(">'o1'").should == @place_o1
      @net.find_place_by_name(">'o2'").should == @place_o2
      @net.find_place_by_name(">'o3'").should == @place_o3
      @net.find_place_by_name(Util::UUID.generate).should.nil
    end

    it "should find all places by name" do
      @net.find_all_places_by_name("'i1'").tap do |places|
        places.size.should == 1
        places.should.include @place_i1
      end

      @net.find_all_places_by_name("'i2'").tap do |places|
        places.size.should == 1
        places.should.include @place_i2
      end

      @net.find_all_places_by_name("'i3'").tap do |places|
        places.size.should == 1
        places.should.include @place_i3
      end

      @net.find_all_places_by_name("'p1'").tap do |places|
        places.size.should == 1
        places.should.include @place_p1
      end

      @net.find_all_places_by_name(">'o1'").tap do |places|
        places.size.should == 1
        places.should.include @place_o1
      end

      @net.find_all_places_by_name(">'o2'").tap do |places|
        places.size.should == 1
        places.should.include @place_o2
      end

      @net.find_all_places_by_name(">'o3'").tap do |places|
        places.size.should == 1
        places.should.include @place_o3
      end

      @net.find_all_places_by_name(Util::UUID.generate).should.empty
    end

    it "should all places by source transition ID" do
      @net.find_all_places_by_source_id(@transition_A.id).tap do |places|
        places.size.should == 1
        places.should.include @place_p1
      end

      @net.find_all_places_by_source_id(@transition_B.id).tap do |places|
        places.size.should == 3
        places.should.include @place_o1
        places.should.include @place_o2
        places.should.include @place_o3
      end
    end

    it "should all places by target transition ID" do
      @net.find_all_places_by_target_id(@transition_A.id).tap do |places|
        places.size.should == 3
        places.should.include @place_i1
        places.should.include @place_i2
        places.should.include @place_i3
      end

      @net.find_all_places_by_target_id(@transition_B.id).tap do |places|
        places.size.should == 1
        places.should.include @place_p1
      end
    end
  end
end

describe Pione::PNML::Place do
  it "should distinguish empty names" do
    PNML::Place.new(PNML::Net.new, Util::UUID.generate, "a").should.not.empty_name
    PNML::Place.new(PNML::Net.new, Util::UUID.generate, "").should.empty_name
    PNML::Place.new(PNML::Net.new, Util::UUID.generate, " ").should.empty_name
    PNML::Place.new(PNML::Net.new, Util::UUID.generate, "  #abc").should.empty_name
  end
end

describe Pione::PNML::Transition do
  it "should distinguish empty names" do
    PNML::Transition.new(PNML::Net.new, Util::UUID.generate, "a").should.not.empty_name
    PNML::Transition.new(PNML::Net.new, Util::UUID.generate, "").should.empty_name
    PNML::Transition.new(PNML::Net.new, Util::UUID.generate, " ").should.empty_name
    PNML::Transition.new(PNML::Net.new, Util::UUID.generate, "  #abc").should.empty_name
  end
end

TestHelper.scope do |this|
  this::SAMPLE_NET = Location[__FILE__].dirname + "data" + "SampleNet.pnml"

  describe Pione::PNML::Arc do
    before do
      @net = PNML::Reader.read(this::SAMPLE_NET)
      @transition_A = @net.find_transition_by_name("A")
      @transition_B = @net.find_transition_by_name("B")
      @place_i1 = @net.find_place_by_name("'i1'")
      @place_i2 = @net.find_place_by_name("'i2'")
      @place_i3 = @net.find_place_by_name("'i3'")
      @place_p1 = @net.find_place_by_name("'p1'")
      @place_o1 = @net.find_place_by_name(">'o1'")
      @place_o2 = @net.find_place_by_name(">'o2'")
      @place_o3 = @net.find_place_by_name(">'o3'")
      @arc_i1_A = @net.find_arc(@place_i1.id, @transition_A.id)
      @arc_i2_A = @net.find_arc(@place_i2.id, @transition_A.id)
      @arc_i3_A = @net.find_arc(@place_i3.id, @transition_A.id)
      @arc_A_p1 = @net.find_arc(@transition_A.id, @place_p1.id)
      @arc_p1_B = @net.find_arc(@place_p1.id, @transition_B.id)
      @arc_B_o1 = @net.find_arc(@transition_B.id, @place_o1.id)
      @arc_B_o2 = @net.find_arc(@transition_B.id, @place_o2.id)
      @arc_B_o3 = @net.find_arc(@transition_B.id, @place_o3.id)
    end

    it "should distinguish the direction from transition to place" do
      @arc_i1_A.should.not.from_transition_to_place
      @arc_i2_A.should.not.from_transition_to_place
      @arc_i3_A.should.not.from_transition_to_place
      @arc_A_p1.should.from_transition_to_place
      @arc_B_o1.should.from_transition_to_place
      @arc_B_o1.should.from_transition_to_place
      @arc_B_o1.should.from_transition_to_place
    end

    it "should distinguish the direction from place to transition" do
      @arc_i1_A.should.from_place_to_transition
      @arc_i2_A.should.from_place_to_transition
      @arc_i3_A.should.from_place_to_transition
      @arc_A_p1.should.not.from_place_to_transition
      @arc_B_o1.should.not.from_place_to_transition
      @arc_B_o1.should.not.from_place_to_transition
      @arc_B_o1.should.not.from_place_to_transition
    end
  end
end
