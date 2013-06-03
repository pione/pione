require_relative '../test-util'

describe 'Pione::Transformer::LiteralTransformer' do
  transformer_spec('boolean', :boolean) do
    tc('true' => BooleanSequence.new([PioneBoolean.true]))
    tc('false' => BooleanSequence.new([PioneBoolean.false]))
  end

  transformer_spec('string', :string) do
    tc('"abc"' => StringSequence.new([PioneString.new('abc')]))
    tc('"a\bc"' => StringSequence.new([PioneString.new('abc')]))
    tc('"a\'"' => StringSequence.new([PioneString.new('a\'')]))
    tc('"a\""' => StringSequence.new([PioneString.new('a"')]))
  end

  transformer_spec('integer', :integer) do
    tc('1' => IntegerSequence.new([PioneInteger.new(1)]))
    tc('123' => IntegerSequence.new([PioneInteger.new(123)]))
    tc('01' => IntegerSequence.new([PioneInteger.new(1)]))
    tc('000123' => IntegerSequence.new([PioneInteger.new(123)]))
    tc('-1' => IntegerSequence.new([PioneInteger.new(-1)]))
    tc('-01' => IntegerSequence.new([PioneInteger.new(-1)]))
    tc('+1' => IntegerSequence.new([PioneInteger.new(1)]))
    tc('+01' => IntegerSequence.new([PioneInteger.new(1)]))
  end

  transformer_spec('float', :float) do
    tc('0.1' => FloatSequence.new([PioneFloat.new(0.1)]))
    tc('123.1' => FloatSequence.new([PioneFloat.new(123.1)]))
    tc('01.23' => FloatSequence.new([PioneFloat.new(1.23)]))
    tc('000123.456' => FloatSequence.new([PioneFloat.new(123.456)]))
    tc('-1.2' => FloatSequence.new([PioneFloat.new(-1.2)]))
    tc('-01.1' => FloatSequence.new([PioneFloat.new(-1.1)]))
    tc('+1.9' => FloatSequence.new([PioneFloat.new(1.9)]))
    tc('+01.8' => FloatSequence.new([PioneFloat.new(1.8)]))
  end

  transformer_spec('variable', :variable) do
    tc("$Var" => Variable.new('Var'))
    tc("$var" => Variable.new('var'))
  end

  transformer_spec('data_name', :data_name) do
    tc("'abc'" => DataExpr.new('abc').to_seq)
    tc("'a\\bc'" => DataExpr.new('abc').to_seq)
    tc("'a\\''" => DataExpr.new("a'").to_seq)
    tc("'a\\\"'" => DataExpr.new("a\"").to_seq)
  end

  transformer_spec('package_name', :package_name) do
    tc("&abc" => PackageExpr.new('abc'))
    tc("&ABC" => PackageExpr.new('ABC'))
  end

  transformer_spec('rule_name', :rule_name) do
    tc("abc" => RuleExpr.new(PackageExpr.new("Main"), "abc"))
  end

  transformer_spec('ticket', :ticket) do
    tc("<T>" => TicketExpr.new("T").to_seq)
    tc("< T>" => TicketExpr.new("T").to_seq)
    tc("<T >" => TicketExpr.new("T").to_seq)
  end
end
