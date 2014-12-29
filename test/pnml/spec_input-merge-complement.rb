require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[__FILE__].dirname + "data"
  this::SIMPLE = this::DIR + "InputMergeComplementSimple.pnml"
  this::COMPLEX = this::DIR + "InputMergeComplementComplex.pnml"

  describe Pione::PNML::InputMergeComplement do
    it "should name by `input merge` in simple case" do
      env = Lang::Environment.new
      net = PNML::Reader.read(this::SIMPLE)

      # transition
      transition_A = net.find_transition_by_name("A")
      place = net.find_all_places_by_target_id(transition_A.id).first

      # apply "input merge complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::InputMergeComplement}.rewrite(net, env)

      # test
      place.name.should == "<'i1' or 'i2' or 'i3'"
    end

    it "should name by `input merge` in complex case" do
      env = Lang::Environment.new
      net = PNML::Reader.read(this::COMPLEX)

      # transition
      transition_A = net.find_transition_by_name("A")
      transition_B = net.find_transition_by_name("B")
      place_LA = net.find_all_places_by_target_id(transition_A.id).first
      place_LB = net.find_all_places_by_target_id(transition_B.id).first

      # apply "input merge complement" rule
      PNML::NetRewriter.new{|rules| rules << PNML::InputMergeComplement}.rewrite(net, env)

      # test
      place_LA.name.should == "<'i1' or 'i2' or 'i3'"
      place_LB.name.should == "<'i2' or 'i3' or 'i4'"
    end
  end
end
