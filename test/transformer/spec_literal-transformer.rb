require_relative '../test-util'

describe 'Pione::Transformer::LiteralTransformer' do
  transformer_spec('boolean', :boolean) do
    test('true', BooleanSequence.of(true))
    test('false', BooleanSequence.of(false))
  end

  transformer_spec('string', :string) do
    test('"abc"', StringSequence.new([PioneString.new('abc')]))
    test('"a\bc"', StringSequence.new([PioneString.new('abc')]))
    test('"a\'"', StringSequence.new([PioneString.new('a\'')]))
    test('"a\""', StringSequence.new([PioneString.new('a"')]))
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
    test('0.1', FloatSequence.new([PioneFloat.new(0.1)]))
    test('123.1', FloatSequence.new([PioneFloat.new(123.1)]))
    test('01.23', FloatSequence.new([PioneFloat.new(1.23)]))
    test('000123.456', FloatSequence.new([PioneFloat.new(123.456)]))
    test('-1.2', FloatSequence.new([PioneFloat.new(-1.2)]))
    test('-01.1', FloatSequence.new([PioneFloat.new(-1.1)]))
    test('+1.9', FloatSequence.new([PioneFloat.new(1.9)]))
    test('+01.8', FloatSequence.new([PioneFloat.new(1.8)]))
  end

  transformer_spec('variable', :variable) do
    test("$Var", Variable.new('Var'))
    test("$var", Variable.new('var'))
  end

  transformer_spec('data_name', :data_name) do
    test("'abc'", DataExpr.new('abc').to_seq)
    test("'a\\bc'", DataExpr.new('abc').to_seq)
    test("'a\\''", DataExpr.new("a'").to_seq)
    test("'a\\\"'", DataExpr.new("a\"").to_seq)
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
