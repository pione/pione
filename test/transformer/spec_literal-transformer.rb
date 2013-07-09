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
    test("null", DataExprSequence.of(DataExprNull.instance))
  end

  transformer_spec('package_name', :package_name) do
    test("&abc", PackageExpr.new('abc'))
    test("&ABC", PackageExpr.new('ABC'))
  end

  transformer_spec('rule_name', :rule_name) do
    test("abc", RuleExpr.new(PackageExpr.new("Main"), "abc"))
  end

  transformer_spec('ticket', :ticket) do
    test("<T>", TicketExpr.new("T").to_seq)
    test("<t>", TicketExpr.new("t").to_seq)
  end
end
