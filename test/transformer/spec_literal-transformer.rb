require_relative '../test-util'

describe 'Pione::Transformer::LiteralTransformer' do
  transformer_spec('boolean', :boolean) do
    # literal true
    test('true', BooleanSequence.of(true))

    # literal false
    test('false', BooleanSequence.of(false))
  end

  transformer_spec('string', :string) do
    test('"abc"', StringSequence.of('abc'))
    test('"a\bc"', StringSequence.of('abc'))
    test('"a\'"', StringSequence.of('a\''))
    test('"a\""', StringSequence.of('a"'))
  end

  transformer_spec('integer', :integer) do
    test('1', IntegerSequence.of(1))
    test('123', IntegerSequence.of(123))
    test('01', IntegerSequence.of(1))
    test('000123', IntegerSequence.of(123))
    test('-1', IntegerSequence.of(-1))
    test('-01', IntegerSequence.of(-1))
    test('+1', IntegerSequence.of(1))
    test('+01', IntegerSequence.of(1))
  end

  transformer_spec('float', :float) do
    test('0.1', FloatSequence.of(0.1))
    test('123.1', FloatSequence.of(123.1))
    test('01.23', FloatSequence.of(1.23))
    test('000123.456', FloatSequence.of(123.456))
    test('-1.2', FloatSequence.of(-1.2))
    test('-01.1', FloatSequence.of(-1.1))
    test('+1.9', FloatSequence.of(1.9))
    test('+01.8', FloatSequence.of(1.8))
  end

  transformer_spec('variable', :variable) do
    test("$Var", Variable.new('Var'))
    test("$var", Variable.new('var'))
  end

  transformer_spec("data_expr", :expr) do
    # literal data expression
    test("'test.a'", DataExprSequence.of("test.a"))

    # wildcard
    test("'*.a'", DataExprSequence.of("*.a"))

    # with escape
    test("'a\\bc'", DataExprSequence.of('abc'))

    # sigle quote with escape
    test("'a\\''", DataExprSequence.of("a'"))

    # double quote with escape
    test("'a\\\"'", DataExprSequence.of("a\""))

    # null
    test("null", DataExprSequence.of(DataExprNull.new))
  end

  transformer_spec('package_expr', :package_expr) do
    test("&abc", PackageExprSequence.of('abc'))
    test("&ABC", PackageExprSequence.of('ABC'))
  end

  transformer_spec('rule_expr', :rule_expr) do
    test("abc", RuleExprSequence.of("abc"))
  end

  transformer_spec('ticket_expr', :ticket_expr) do
    test("<T>", TicketExprSequence.of("T"))
    test("<t>", TicketExprSequence.of("t"))
  end

  transformer_spec("parameters", :expr) do
    test("{}", ParameterSetSequence.new)

    test "{X: 1}" do |params|
      params.should.kind_of Model::ParameterSetSequence
      params.pieces.first.table["X"].should == IntegerSequence.of(1)
    end

    test "{X: 1, Y: 2}" do |params|
      params.should.kind_of Model::ParameterSetSequence
      params.pieces.first.table["X"].should == IntegerSequence.of(1)
      params.pieces.first.table["Y"].should == IntegerSequence.of(2)
    end

    test "{X: \"a\", Y: \"b\", Z: \"c\"}" do |params|
      params.should.kind_of Model::ParameterSetSequence
      params.pieces.first.table["X"].should == StringSequence.of("a")
      params.pieces.first.table["Y"].should == StringSequence.of("b")
      params.pieces.first.table["Z"].should == StringSequence.of("c")
    end
  end

  transformer_spec("feature", :feature) do
    test('+A', Model::FeatureSequence.of(Model::RequisiteFeature.new("A")))
    test('-A', Model::FeatureSequence.of(Model::BlockingFeature.new("A")))
    test('?A', Model::FeatureSequence.of(Model::PreferredFeature.new("A")))
    test('^A', Model::FeatureSequence.of(Model::PossibleFeature.new("A")))
    test('!A', Model::FeatureSequence.of(Model::RestrictiveFeature.new("A")))
    test('*', Model::FeatureSequence.of(EmptyFeature.new))
    test('**', Model::FeatureSequence.of(AlmightyFeature.new))
  end
end
