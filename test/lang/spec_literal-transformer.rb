require 'pione/test-helper'

describe 'Pione::Transformer::LiteralTransformer' do
  transformer_spec('boolean', :boolean) do
    # literal true
    test('true', Lang::BooleanSequence.of(true))

    # literal false
    test('false', Lang::BooleanSequence.of(false))
  end

  transformer_spec('string', :string) do
    test('"abc"', Lang::StringSequence.of('abc'))
    test('"a\bc"', Lang::StringSequence.of('abc'))
    test('"a\'"', Lang::StringSequence.of('a\''))
    test('"a\""', Lang::StringSequence.of('a"'))
  end

  transformer_spec('integer', :integer) do
    test('1', Lang::IntegerSequence.of(1))
    test('123', Lang::IntegerSequence.of(123))
    test('01', Lang::IntegerSequence.of(1))
    test('000123', Lang::IntegerSequence.of(123))
    test('-1', Lang::IntegerSequence.of(-1))
    test('-01', Lang::IntegerSequence.of(-1))
    test('+1', Lang::IntegerSequence.of(1))
    test('+01', Lang::IntegerSequence.of(1))
  end

  transformer_spec('float', :float) do
    test('0.1', Lang::FloatSequence.of(0.1))
    test('123.1', Lang::FloatSequence.of(123.1))
    test('01.23', Lang::FloatSequence.of(1.23))
    test('000123.456', Lang::FloatSequence.of(123.456))
    test('-1.2', Lang::FloatSequence.of(-1.2))
    test('-01.1', Lang::FloatSequence.of(-1.1))
    test('+1.9', Lang::FloatSequence.of(1.9))
    test('+01.8', Lang::FloatSequence.of(1.8))
  end

  transformer_spec('variable', :variable) do
    test("$Var", Lang::Variable.new('Var'))
    test("$var", Lang::Variable.new('var'))
  end

  transformer_spec("data_expr", :expr) do
    # literal data expression
    test("'test.a'", Lang::DataExprSequence.of("test.a"))

    # wildcard
    test("'*.a'", Lang::DataExprSequence.of("*.a"))

    # with escape
    test("'a\\bc'", Lang::DataExprSequence.of('abc'))

    # sigle quote with escape
    test("'a\\''", Lang::DataExprSequence.of("a'"))

    # double quote with escape
    test("'a\\\"'", Lang::DataExprSequence.of("a\""))

    # null
    test("null", Lang::DataExprSequence.of(Lang::DataExprNull.new))
  end

  transformer_spec('package_expr', :package_expr) do
    test("&abc", Lang::PackageExprSequence.of('abc'))
    test("&ABC", Lang::PackageExprSequence.of('ABC'))
  end

  transformer_spec('rule_expr', :rule_expr) do
    test("abc", Lang::RuleExprSequence.of("abc"))
  end

  transformer_spec('ticket_expr', :ticket_expr) do
    test("<T>", Lang::TicketExprSequence.of("T"))
    test("<t>", Lang::TicketExprSequence.of("t"))
  end

  transformer_spec("parameters", :expr) do
    test("{}", Lang::ParameterSetSequence.new)

    test "{X: 1}" do |params|
      params.should.kind_of Lang::ParameterSetSequence
      params.pieces.first.table["X"].should == Lang::IntegerSequence.of(1)
    end

    test "{X: 1, Y: 2}" do |params|
      params.should.kind_of Lang::ParameterSetSequence
      params.pieces.first.table["X"].should == Lang::IntegerSequence.of(1)
      params.pieces.first.table["Y"].should == Lang::IntegerSequence.of(2)
    end

    test "{X: \"a\", Y: \"b\", Z: \"c\"}" do |params|
      params.should.kind_of Lang::ParameterSetSequence
      params.pieces.first.table["X"].should == Lang::StringSequence.of("a")
      params.pieces.first.table["Y"].should == Lang::StringSequence.of("b")
      params.pieces.first.table["Z"].should == Lang::StringSequence.of("c")
    end
  end

  transformer_spec("feature", :feature) do
    test('+A', Lang::FeatureSequence.of(Lang::RequisiteFeature.new("A")))
    test('-A', Lang::FeatureSequence.of(Lang::BlockingFeature.new("A")))
    test('?A', Lang::FeatureSequence.of(Lang::PreferredFeature.new("A")))
    test('^A', Lang::FeatureSequence.of(Lang::PossibleFeature.new("A")))
    test('!A', Lang::FeatureSequence.of(Lang::RestrictiveFeature.new("A")))
    test('*', Lang::FeatureSequence.of(Lang::EmptyFeature.new))
    test('**', Lang::FeatureSequence.of(Lang::AlmightyFeature.new))
  end
end
