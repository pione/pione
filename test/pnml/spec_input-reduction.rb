require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[__FILE__].dirname + "data"
  this::SIMPLE = this::DIR + "InputReductionSimple.pnml"
  this::COMPLEX = this::DIR + "InputReductionComplex.pnml"
  this::LONG = this::DIR + "InputReductionLong.pnml"

  describe Pione::PNML::InputReduction do
    it "should reduce nodes by `input reduction` in simple case" do
      net = PNML::Reader.read(this::SIMPLE)

      # save net elements
      transition_A = net.transitions.find {|transition| transition.name == "A"}
      place_i1 = net.find_place_by_name("<'i1'")
      place_o1 = net.find_place_by_name(">'o1'")
      arc_A_o1 = net.find_arc(transition_A.id, place_o1.id)

      # apply input reduction
      PNML::NetRewriter.new{|rules| rules << PNML::InputReduction}.rewrite(net)

      # test transitions
      net.transitions.size.should == 1
      net.transitions.should.include transition_A

      # test places
      net.places.size.should == 2
      net.places.should.include place_i1
      net.places.should.include place_o1

      # test arcs
      net.arcs.size.should == 2
      net.find_arc(place_i1.id, transition_A.id).should.kind_of PNML::Arc
      net.find_arc(transition_A.id, place_o1.id).should == arc_A_o1
    end

    it "should reduce nodes by `input reduction` in complex case" do
      net = PNML::Reader.read(this::COMPLEX)

      # save net elements
      transition_A = net.find_transition_by_name("A")
      place_i1 = net.find_place_by_name("<'i1'")
      place_i2 = net.find_place_by_name("<'i2'")
      place_i3 = net.find_place_by_name("<'i3'")
      place_o1 = net.find_place_by_name(">'o1'")

      # apply output reduction
      PNML::NetRewriter.new{|rules| rules << PNML::InputReduction}.rewrite(net)

      # test transitions
      net.transitions.size.should == 1
      net.transitions.first.should == transition_A

      # test places
      net.places.size.should == 4
      net.places.should.include place_i1
      net.places.should.include place_i2
      net.places.should.include place_i3
      net.places.should.include place_o1

      # test arcs
      net.arcs.size.should == 4
      net.find_arc(place_i1.id, transition_A.id).should.not.nil
      net.find_arc(place_i2.id, transition_A.id).should.not.nil
      net.find_arc(place_i3.id, transition_A.id).should.not.nil
      net.find_arc(transition_A.id, place_o1.id).should.not.nil
    end

    it "should reduce nodes by `input reduction` in long case" do
      net = PNML::Reader.read(this::LONG)

      # save net elements
      transition_A = net.transitions.find {|transition| transition.name == "A"}
      place_i1 = net.find_place_by_name("<'i1'")
      place_o1 = net.find_place_by_name(">'o1'")
      arc_A_o1 = net.find_arc(transition_A.id, place_o1.id)

      # apply input reduction
      PNML::NetRewriter.new{|rules| rules << PNML::InputReduction}.rewrite(net)

      # test transitions
      net.transitions.size.should == 1
      net.transitions.should.include transition_A

      # test places
      net.places.size.should == 2
      net.places.should.include place_i1
      net.places.should.include place_o1

      # test arcs
      net.arcs.size.should == 2
      net.find_arc(place_i1.id, transition_A.id).should.kind_of PNML::Arc
      net.find_arc(transition_A.id, place_o1.id).should == arc_A_o1
    end

    it "should not reduce any nodes if there aren't output reducible nodes" do
      net = PNML::Reader.read(this::DIR + "OutputReductionSimple.pnml")

      # save net elements
      places = net.places.clone
      transitions = net.transitions.clone
      arcs = net.arcs.clone

      # apply input reduction
      PNML::NetRewriter.new{|rules| rules << PNML::InputReduction}.rewrite(net)

      # test
      net.places.should == places
      net.transitions.should == transitions
      net.arcs.should == arcs
    end
  end
end
