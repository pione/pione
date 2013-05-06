require_relative '../test-util'

describe 'Pione::Transformer::LiteralTransformer' do
  transformer_spec('boolean', :boolean) do
    tc('true' => PioneBooleanSequence.new([PioneBoolean.true]))
    tc('false' => PioneBooleanSequence.new([PioneBoolean.false]))
  end

  transformer_spec('string', :string) do
    tc('"abc"' => PioneStringSequence.new([PioneString.new('abc')]))
    tc('"a\bc"' => PioneStringSequence.new([PioneString.new('abc')]))
    tc('"a\'"' => PioneStringSequence.new([PioneString.new('a\'')]))
    tc('"a\""' => PioneStringSequence.new([PioneString.new('a"')]))
  end

  transformer_spec('integer', :integer) do
    tc('1' => PioneIntegerSequence.new([PioneInteger.new(1)]))
    tc('123' => PioneIntegerSequence.new([PioneInteger.new(123)]))
    tc('01' => PioneIntegerSequence.new([PioneInteger.new(1)]))
    tc('000123' => PioneIntegerSequence.new([PioneInteger.new(123)]))
    tc('-1' => PioneIntegerSequence.new([PioneInteger.new(-1)]))
    tc('-01' => PioneIntegerSequence.new([PioneInteger.new(-1)]))
    tc('+1' => PioneIntegerSequence.new([PioneInteger.new(1)]))
    tc('+01' => PioneIntegerSequence.new([PioneInteger.new(1)]))
  end

  transformer_spec('float', :float) do
    tc('0.1' => PioneFloatSequence.new([PioneFloat.new(0.1)]))
    tc('123.1' => PioneFloatSequence.new([PioneFloat.new(123.1)]))
    tc('01.23' => PioneFloatSequence.new([PioneFloat.new(1.23)]))
    tc('000123.456' => PioneFloatSequence.new([PioneFloat.new(123.456)]))
    tc('-1.2' => PioneFloatSequence.new([PioneFloat.new(-1.2)]))
    tc('-01.1' => PioneFloatSequence.new([PioneFloat.new(-1.1)]))
    tc('+1.9' => PioneFloatSequence.new([PioneFloat.new(1.9)]))
    tc('+01.8' => PioneFloatSequence.new([PioneFloat.new(1.8)]))
  end

  transformer_spec('variable', :variable) do
    tc("$Var" => Variable.new('Var'))
    tc("$var" => Variable.new('var'))
  end

  transformer_spec('data_name', :data_name) do
    tc("'abc'" => DataExpr.new('abc'))
    tc("'a\\bc'" => DataExpr.new('abc'))
    tc("'a\\''" => DataExpr.new("a'"))
    tc("'a\\\"'" => DataExpr.new("a\""))
  end

  transformer_spec('package_name', :package_name) do
    tc("&abc" => Package.new('abc'))
    tc("&ABC" => Package.new('ABC'))
  end

  transformer_spec('rule_name', :rule_name) do
    tc("abc" => RuleExpr.new(Package.new("main"), "abc"))
  end

  transformer_spec('ticket', :ticket) do
    tc("<T>" => TicketExpr.new(["T"]))
    tc("< T>" => TicketExpr.new(["T"]))
    tc("<T >" => TicketExpr.new(["T"]))
  end
end
