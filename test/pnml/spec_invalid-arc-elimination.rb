require 'pione/test-helper'

describe Pione::PNML::InvalidArcElimination do
  it "should eliminate invalid arcs" do
    env = Lang::Environment.new
    net = PNML::Net.new

    # place and transition
    place = PNML::Place.new(net, net.generate_id)
    net.places << place
    transition = PNML::Transition.new(net, net.generate_id)
    net.transitions << transition

    # valid arc
    valid_arc = PNML::Arc.new(net, net.generate_id, place.id, transition.id)
    net.arcs << valid_arc

    # invalid arcs
    net.arcs << PNML::Arc.new(net, net.generate_id, net.generate_id, net.generate_id)
    net.arcs << PNML::Arc.new(net, net.generate_id, place.id, net.generate_id)
    net.arcs << PNML::Arc.new(net, net.generate_id, net.generate_id, place.id)
    net.arcs << PNML::Arc.new(net, net.generate_id, transition.id, net.generate_id)
    net.arcs << PNML::Arc.new(net, net.generate_id, net.generate_id, transition.id)
    net.arcs << PNML::Arc.new(net, net.generate_id, place.id, place.id)
    net.arcs << PNML::Arc.new(net, net.generate_id, transition.id, transition.id)

    # apply "invalid arc elimination" rule
    PNML::NetRewriter.new{|rules| rules << PNML::InvalidArcElimination}.rewrite(net, env)

    # test
    net.arcs.size.should == 1
    net.arcs.should.include valid_arc
  end
end
