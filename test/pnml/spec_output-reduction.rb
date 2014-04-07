require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[__FILE__].dirname + "data"
  this::SIMPLE = this::DIR + "OutputReductionSimple.pnml"
  this::COMPLEX = this::DIR + "OutputReductionComplex.pnml"
  this::LONG = this::DIR + "OutputReductionLong.pnml"

  describe Pione::PNML::OutputReduction do
    it "should reduce nodes by `output reduction` in simple case" do
      net = PNML::Reader.read(this::SIMPLE)

      # save elements
      transition_A = net.find_transition_by_name("A")
      place_i1 = net.find_place_by_name("'i1'")
      place_o1 = net.find_place_by_name(">'o1'")
      arc_i1_A = net.find_arc(place_i1.id, transition_A.id)

      # apply output reduction
      PNML::NetRewriter.new{|rules| rules << PNML::OutputReduction}.rewrite(net)

      # test transitions
      net.transitions.size.should == 1
      net.transitions.first.should == transition_A

      # test places
      net.places.size.should == 2
      net.places.should.include place_i1
      net.places.should.include place_o1

      # test arcs
      net.arcs.size.should == 2
      net.find_arc(place_i1.id, transition_A.id).should == arc_i1_A
      net.find_arc(transition_A.id, place_o1.id).should.kind_of PNML::Arc
    end

    it "should reduce nodes by `output reduction` in complex case" do
      net = PNML::Reader.read(this::COMPLEX)

      # save net elements
      transition_A = net.transitions.find {|transition| transition.name == "A"}
      place_i1 = net.find_place_by_name("'i1'")
      place_o1 = net.find_place_by_name(">'o1'")
      place_o2 = net.find_place_by_name(">'o2'")
      place_o3 = net.find_place_by_name(">'o3'")
      arc_i1_A = net.find_arc(place_i1.id, transition_A.id)

      # apply output reduction
      PNML::NetRewriter.new{|rules| rules << PNML::OutputReduction}.rewrite(net)

      # test transitions
      net.transitions.size.should == 1
      net.transitions.first.should == transition_A

      # test places
      net.places.size.should == 4
      net.places.should.include place_i1
      net.places.should.include place_o1
      net.places.should.include place_o2
      net.places.should.include place_o3

      # test arcs
      net.arcs.size.should == 4
      net.find_arc(place_i1.id, transition_A.id).should == arc_i1_A
      net.find_arc(transition_A.id, place_o1.id).should.kind_of PNML::Arc
      net.find_arc(transition_A.id, place_o2.id).should.kind_of PNML::Arc
      net.find_arc(transition_A.id, place_o3.id).should.kind_of PNML::Arc
    end

    it "should reduce nodes by `output reduction` in long case" do
      net = PNML::Reader.read(this::LONG)

      # save elements
      transition_A = net.transitions.find {|transition| transition.name == "A"}
      place_i1 = net.find_place_by_name("'i1'")
      place_o1 = net.find_place_by_name(">'o1'")
      arc_i1_A = net.find_arc(place_i1.id, transition_A.id)

      # apply output reduction
      PNML::NetRewriter.new{|rules| rules << PNML::OutputReduction}.rewrite(net)

      # test transitions
      net.transitions.size.should == 1
      net.transitions.first.should == transition_A

      # test places
      net.places.size.should == 2
      net.places.should.include place_i1
      net.places.should.include place_o1

      # test arcs
      net.arcs.size.should == 2
      net.find_arc(place_i1.id, transition_A.id).should == arc_i1_A
      net.find_arc(transition_A.id, place_o1.id).should.kind_of PNML::Arc
    end

    it "should not reduce any nodes if there aren't output reducible nodes" do
      net = PNML::Reader.read(this::DIR + "InputReductionSimple.pnml")

      # save net elements
      places = net.places.clone
      transitions = net.transitions.clone
      arcs = net.arcs.clone

      # apply output reduction
      PNML::NetRewriter.new{|rules| rules << PNML::OutputReduction}.rewrite(net)

      # test
      net.places.should == places
      net.transitions.should == transitions
      net.arcs.should == arcs
    end
  end
end
