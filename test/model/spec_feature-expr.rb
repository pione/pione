require_relative '../test-util'

describe 'Feature::Expr' do
  it 'should equal' do
    Feature::PossibleExpr.new("A").should ==
      Feature::PossibleExpr.new("A")
    Feature::RestrictiveExpr.new("A").should ==
      Feature::RestrictiveExpr.new("A")
  end

  it 'should not equal' do
    possible_a = Feature::PossibleExpr.new("A")
    possible_b = Feature::PossibleExpr.new("B")
    restrictive_a = Feature::RestrictiveExpr.new("A")
    restrictive_b = Feature::RestrictiveExpr.new("B")
    requisite_a = Feature::RequisiteExpr.new("A")
    requisite_b = Feature::RequisiteExpr.new("B")
    blocking_a = Feature::BlockingExpr.new("A")
    blocking_b = Feature::BlockingExpr.new("B")
    preferred_a = Feature::PreferredExpr.new("A")
    preferred_b = Feature::PreferredExpr.new("B")
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

  it 'should match' do
    possible = Feature::PossibleExpr.new("A")
    requisite = Feature::RequisiteExpr.new("A")
    possible.match(requisite).should.true
  end

  it 'should not match' do
    possible = Feature::PossibleExpr.new("A")
    requisite = Feature::RequisiteExpr.new("B")
    requisite.match(possible).should.false
  end

  describe 'Feature::EmptyFeature' do
    it 'should be equal' do
      Feature.empty.should == Feature.empty
      Feature.empty.should == Feature.and()
      Feature.empty.should == Feature.or()
    end
  end

  describe 'Feature::AndExpr' do
    it 'should be equal' do
      Feature.and().should == Feature.empty
    end

    it 'should be empty' do
      Feature.and.should.be.empty
    end

    it 'should add elements' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      c = Feature::PossibleExpr.new("C")
      d = Feature::PossibleExpr.new("D")
      and1 = Feature::AndExpr.new(a, b)
      Feature::AndExpr.new(and1, c, d).should ==
        Feature::AndExpr.new(a, b, c, d)
    end

    it 'should unify redundant elements' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      and1 = Feature::AndExpr.new(a, b)
      Feature::AndExpr.new(and1, a, b).should == and1
      Feature::AndExpr.new(and1, and1).should == and1
    end

    it 'should background preferred feature by requisite feature' do
      requisite = Feature::RequisiteExpr.new("A")
      preferred = Feature::PreferredExpr.new("A")
      Feature::AndExpr.new(requisite, preferred).simplify.should ==
        requisite
      Feature::AndExpr.new(preferred, requisite).simplify.should ==
        requisite
    end

    it 'should background preferred feature by blocking feature' do
      blocking = Feature::BlockingExpr.new("A")
      preferred = Feature::PreferredExpr.new("A")
      Feature::AndExpr.new(blocking, preferred).simplify.should ==
        blocking
      Feature::AndExpr.new(preferred, blocking).simplify.should ==
        blocking
    end

    it 'should summarize or-clause' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      c = Feature::PossibleExpr.new("C")
      d = Feature::PossibleExpr.new("D")
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
        Feature::AndExpr.new(Feature::OrExpr.new(a, Feature::AndExpr.new(b, c)),
                             Feature::OrExpr.new(c, d))
    end

    it 'should unify by restrictive feature' do
      possible = Feature::PossibleExpr.new("A")
      restrictive = Feature::RestrictiveExpr.new("A")
      Feature::AndExpr.new(possible, restrictive).simplify.should ==
        restrictive
      Feature::AndExpr.new(restrictive, possible).simplify.should ==
        restrictive
    end

    it 'should expand' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      c = Feature::PossibleExpr.new("C")
      d = Feature::PossibleExpr.new("D")
      or1 = Feature::OrExpr.new(a, b)
      or2 = Feature::OrExpr.new(c, d)
      list = Feature::AndExpr.new(or1, or2).expander.to_a
      list.size.should == 4
      list.should.include Feature::AndExpr.new(a, c)
      list.should.include Feature::AndExpr.new(a, d)
      list.should.include Feature::AndExpr.new(b, c)
      list.should.include Feature::AndExpr.new(b, d)
    end

    it 'should clone with the set' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      expr = Feature::AndExpr.new(a, b)
      expr.clone.should == expr
      expr.clone.__id__.should.not == expr.__id__
    end
  end

  describe 'Feature::OrExpr' do
    it 'should add elements' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      c = Feature::PossibleExpr.new("C")
      d = Feature::PossibleExpr.new("D")
      expr = Feature::OrExpr.new(a, b)
      Feature::OrExpr.new(expr, c, d).should ==
        Feature::OrExpr.new(a, b, c, d)
    end

    it 'should unify redundant elements' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      expr = Feature::OrExpr.new(a, b)
      Feature::OrExpr.new(expr, a, b).should == expr
      Feature::OrExpr.new(expr, expr).should == expr
    end

    it 'should foreground preferred feature over requisite feature' do
      requisite = Feature::RequisiteExpr.new("A")
      preferred = Feature::PreferredExpr.new("A")
      Feature::OrExpr.new(requisite, preferred).simplify.should ==
        preferred
      Feature::OrExpr.new(preferred, requisite).simplify.should ==
        preferred
    end

    it 'should foreground preferred feature over blocking feature' do
      blocking = Feature::BlockingExpr.new("A")
      preferred = Feature::PreferredExpr.new("A")
      Feature::OrExpr.new(blocking, preferred).simplify.should ==
        preferred
      Feature::OrExpr.new(preferred, blocking).simplify.should ==
        preferred
    end

    it 'should unify by possible feature' do
      possible = Feature::PossibleExpr.new("A")
      restrictive = Feature::RestrictiveExpr.new("A")
      Feature::OrExpr.new(possible, restrictive).simplify.should ==
        possible
      Feature::OrExpr.new(restrictive, possible).simplify.should ==
        possible
    end

    it 'should neutralize' do
      requisite = Feature::RequisiteExpr.new("A")
      blocking = Feature::BlockingExpr.new("A")
      Feature::OrExpr.new(requisite, blocking).simplify.should ==
        Feature::EmptyFeature.new
      Feature::OrExpr.new(blocking, requisite).simplify.should ==
        Feature::EmptyFeature.new
    end

    it 'should expand' do
      a = Feature::PossibleExpr.new("A")
      b = Feature::PossibleExpr.new("B")
      c = Feature::PossibleExpr.new("C")
      d = Feature::PossibleExpr.new("D")
      and1 = Feature::AndExpr.new(a, b)
      and2 = Feature::AndExpr.new(c, d)
      list = Feature::OrExpr.new(and1, and2).expander.to_a
      list.size.should == 2
      list.should.include Feature::AndExpr.new(a, b)
      list.should.include Feature::AndExpr.new(c, d)
    end

    it 'should be empty' do
      Feature::AndExpr.new(Feature::EmptyFeature.new).should.be.empty
    end
  end

  #
  # test cases
  #
  yamlname = 'spec_feature-expr.yml'
  ymlpath = File.join(File.dirname(__FILE__), yamlname)
  testcases = YAML.load_file(ymlpath)

  describe 'Feature::Sentence' do
    it 'should get true' do
      possible_a = Feature::PossibleExpr.new("A")
      possible_b = Feature::PossibleExpr.new("B")
      provider = Feature::OrExpr.new(possible_a, possible_b)
      requisite_a = Feature::RequisiteExpr.new("A")
      requisite_b = Feature::RequisiteExpr.new("B")
      request = Feature::OrExpr.new(requisite_a, requisite_b)
      Feature::Sentence.new(provider, request).decide.should.be.true
    end

    it 'should eliminate requisite feature' do
      possible = Feature::PossibleExpr.new("A")
      requisite = Feature::RequisiteExpr.new("A")
      provider = Feature::AndExpr.new(possible)
      request = Feature::AndExpr.new(requisite)
      m = Feature::Sentence::EliminationMethod
      result, p, r = m.eliminate_requisite_feature(provider, request)
      result.should.be.true
      p.should.empty
      r.should.empty
    end

    it 'should eliminate blocking feature' do
      possible = Feature::PossibleExpr.new("X")
      requisite = Feature::RequisiteExpr.new("Y")
      blocking = Feature::BlockingExpr.new("Z")
      provider = Feature::AndExpr.new(possible)
      request = Feature::AndExpr.new(requisite, blocking)
      m = Feature::Sentence::EliminationMethod
      result, p, r = m.eliminate_blocking_feature(provider, request)
      result.should.be.true
      p.should == Feature::AndExpr.new(possible)
      r.should == Feature::AndExpr.new(requisite)
    end

    it 'should eliminate preferred feature' do
      possible = Feature::PossibleExpr.new("X")
      requisite = Feature::RequisiteExpr.new("Y")
      preferred = Feature::PreferredExpr.new("Z")
      provider = Feature::AndExpr.new(possible)
      request = Feature::AndExpr.new(requisite, preferred)
      m = Feature::Sentence::EliminationMethod
      result, p, r = m.eliminate_preferred_feature(provider, request)
      result.should.be.true
      p.should == Feature::AndExpr.new(possible)
      r.should == Feature::AndExpr.new(requisite)
    end

    it 'should eliminate or-clause including empty feature' do
      possible1 = Feature::PossibleExpr.new("X")
      possible2 = Feature::PossibleExpr.new("Y")
      or_clause = Feature::OrExpr.new(Feature::EmptyFeature.new, possible1)
      provider = Feature::AndExpr.new(or_clause, possible2)
      request = Feature::AndExpr.new(Feature::EmptyFeature.new)
      m = Feature::Sentence::EliminationMethod
      result, p, r = m.eliminate_or_clause_including_empty_feature(provider, request)
      result.should.be.true
      p.should == Feature::AndExpr.new(possible2)
      r.should.be.empty
    end

    it 'should eliminate possible feature' do
      possible1 = Feature::PossibleExpr.new("X")
      possible2 = Feature::PossibleExpr.new("Y")
      requisite = Feature::RequisiteExpr.new("Y")
      provider = Feature::AndExpr.new(possible1, possible2)
      request = Feature::AndExpr.new(requisite)
      m = Feature::Sentence::EliminationMethod
      result, p, r = m.eliminate_possible_feature(provider, request)
      result.should.be.true
      p.should == Feature::AndExpr.new(possible2)
      r.should == Feature::AndExpr.new(requisite)
    end

    testcases["unification"].each do |type_name, methods|
      methods.each do |method_name, cases|
        cases.each do |case_name, testcase|
          it "should unify %s expression by %s(%s)" % [type_name, method_name, case_name] do
            parser = DocumentParser.new.feature_expr
            expr1 = DocumentTransformer.new.apply(parser.parse(testcase["expr1"]))
            expr2 = DocumentTransformer.new.apply(parser.parse(testcase["expr2"]))
            result = DocumentTransformer.new.apply(parser.parse(testcase["result"]))
            expr1.send(method_name, expr2).should.be.true
          end
        end
      end
    end

    # sentence test cases
    testcases["sentence"].each do |testname, testcase|
      it "should get #{testcase["result"]}: #{testname}" do
        parser = DocumentParser.new.feature_expr
        provide = DocumentTransformer.new.apply(parser.parse(testcase["provide"]))
        request = DocumentTransformer.new.apply(parser.parse(testcase["request"]))
        Feature::Sentence.new(provide, request).decide.should == testcase["result"]
      end
    end
  end

  describe "pione method ==" do
    it 'should get true' do
      requisite_a = Feature::RequisiteExpr.new("X")
      requisite_b = Feature::RequisiteExpr.new("X")
      requisite_a.call_pione_method("==", requisite_b).should ==
        PioneBoolean.true
    end

    it 'should get false' do
      requisite_a = Feature::RequisiteExpr.new("X")
      requisite_b = Feature::RequisiteExpr.new("Y")
      requisite_a.call_pione_method("==", requisite_b).should ==
        PioneBoolean.false
    end
  end

  describe "pione method !=" do
    it 'should get true' do
      requisite_a = Feature::RequisiteExpr.new("X")
      requisite_b = Feature::RequisiteExpr.new("Y")
      requisite_a.call_pione_method("!=", requisite_b).should ==
        PioneBoolean.true
    end

    it 'should get false' do
      requisite_a = Feature::RequisiteExpr.new("X")
      requisite_b = Feature::RequisiteExpr.new("X")
      requisite_a.call_pione_method("!=", requisite_b).should ==
        PioneBoolean.false
    end
  end

  describe "pione method as_string" do
    it 'should get string' do
      requisite = Feature::RequisiteExpr.new("X")
      requisite.call_pione_method("as_string").should ==
        PioneString.new("+X")
      blocking = Feature::BlockingExpr.new("X")
      blocking.call_pione_method("as_string").should ==
        PioneString.new("-X")
    end
  end
end
