require 'pione/test-util'

describe 'Feature::Expr' do
  it 'should equal' do
    Feature::Symbol.new("A").should == Feature::Symbol.new("A")
    Feature::PossibleExpr.new(Feature::Symbol.new("A")).should ==
      Feature::PossibleExpr.new(Feature::Symbol.new("A"))
    Feature::RestrictiveExpr.new(Feature::Symbol.new("A")).should ==
      Feature::RestrictiveExpr.new(Feature::Symbol.new("A"))
  end

  it 'should not equal' do
    a = Feature::Symbol.new("A")
    b = Feature::Symbol.new("B")
    a.should.not == b
    possible_a = Feature::PossibleExpr.new(a)
    possible_b = Feature::PossibleExpr.new(b)
    restrictive_a = Feature::RestrictiveExpr.new(a)
    restrictive_b = Feature::RestrictiveExpr.new(b)
    requisite_a = Feature::RequisiteExpr.new(a)
    requisite_b = Feature::RequisiteExpr.new(b)
    blocking_a = Feature::BlockingExpr.new(a)
    blocking_b = Feature::BlockingExpr.new(b)
    preferred_a = Feature::PreferredExpr.new(a)
    preferred_b = Feature::PreferredExpr.new(b)
    empty = Feature::EmptyFeature.new
    boundless = Feature::BoundlessFeature.new
    possible_a.should.not == possible_b
    possible_a.should.not == restrictive_a
    possible_a.should.not == requisite_a
    possible_a.should.not == blocking_a
    possible_a.should.not == preferred_a
    possible_a.should.not == empty
    possible_a.should.not == boundless
    restrictive_a.should.not == restrictive_b
  end

  describe 'Feature::AndExpr' do
    it 'should add elements' do
      a = Feature::PossibleExpr.new(Feature::Symbol.new("A"))
      b = Feature::PossibleExpr.new(Feature::Symbol.new("B"))
      c = Feature::PossibleExpr.new(Feature::Symbol.new("C"))
      d = Feature::PossibleExpr.new(Feature::Symbol.new("D"))
      and1 = Feature::AndExpr.new(a, b)
      Feature::AndExpr.new(and1, c, d).should ==
        Feature::AndExpr.new(a, b, c, d)
    end

    it 'should unify redundant elements' do
      a = Feature::PossibleExpr.new(Feature::Symbol.new("A"))
      b = Feature::PossibleExpr.new(Feature::Symbol.new("B"))
      and1 = Feature::AndExpr.new(a, b)
      Feature::AndExpr.new(and1, a, b).should == and1
      Feature::AndExpr.new(and1, and1).should == and1
    end

    it 'should background preferred feature by requisite feature' do
      requisite = Feature::RequisiteExpr.new(Feature::Symbol.new("A"))
      preferred = Feature::PreferredExpr.new(Feature::Symbol.new("A"))
      Feature::AndExpr.new(requisite, preferred).simplify.should ==
        requisite
      Feature::AndExpr.new(preferred, requisite).simplify.should ==
        requisite
    end

    it 'should summarize or-clause' do
      a = Feature::PossibleExpr.new(Feature::Symbol.new("A"))
      b = Feature::PossibleExpr.new(Feature::Symbol.new("B"))
      c = Feature::PossibleExpr.new(Feature::Symbol.new("C"))
      d = Feature::PossibleExpr.new(Feature::Symbol.new("D"))
      or1 = Feature::OrExpr.new(a, b)
      or2 = Feature::OrExpr.new(a, c)
      or3 = Feature::OrExpr.new(a, d)
      or4 = Feature::OrExpr.new(c, d)
      Feature::AndExpr.new(or1, or2).simplify.should ==
        Feature::OrExpr.new(a, Feature::AndExpr.new(b, c))
      Feature::AndExpr.new(or2, or1).simplify.should ==
        Feature::OrExpr.new(a, Feature::AndExpr.new(b, c))
      Feature::AndExpr.new(or1, or2, or3).simplify.should ==
        Feature::OrExpr.new(a, Feature::AndExpr.new(b, c, d))
      Feature::AndExpr.new(or1, or2, or4).simplify.should ==
        Feature::OrExpr.new(a, Feature::AndExpr.new(b, c, d))
    end

    it 'should unify by restrictive feature' do
      possible = Feature::PossibleExpr.new(Feature::Symbol.new("A"))
      restrictive = Feature::RestrictiveExpr.new(Feature::Symbol.new("A"))
      Feature::AndExpr.new(possible, restrictive).simplify.should ==
        restrictive
      Feature::AndExpr.new(restrictive, possible).simplify.should ==
        restrictive
    end
  end
end
