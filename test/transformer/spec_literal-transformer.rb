require_relative '../test-util'

describe 'Pione::Transformer::LiteralTransformer' do
  transformer_spec('boolean', :boolean) do
    tc('true' => PioneBoolean.true)
    tc('false' => PioneBoolean.false)
  end

  transformer_spec('string', :string) do
    tc('"abc"' => PioneString.new('abc'))
    tc('"a\bc"' => PioneString.new('abc'))
    tc('"a\'"' => PioneString.new('a\''))
    tc('"a\""' => PioneString.new('a"'))
  end

  transformer_spec('integer', :integer) do
    tc('1' => PioneInteger.new(1))
    tc('123' => PioneInteger.new(123))
    tc('01' => PioneInteger.new(1))
    tc('000123' => PioneInteger.new(123))
    tc('-1' => PioneInteger.new(-1))
    tc('-01' => PioneInteger.new(-1))
    tc('+1' => PioneInteger.new(1))
    tc('+01' => PioneInteger.new(1))
  end

  transformer_spec('float', :float) do
    tc('0.1' => PioneFloat.new(0.1))
    tc('123.1' => PioneFloat.new(123.1))
    tc('01.23' => PioneFloat.new(1.23))
    tc('000123.456' => PioneFloat.new(123.456))
    tc('-1.2' => PioneFloat.new(-1.2))
    tc('-01.1' => PioneFloat.new(-1.1))
    tc('+1.9' => PioneFloat.new(1.9))
    tc('+01.8' => PioneFloat.new(1.8))
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
end
