require 'pione/test-helper'

document_location = Location[File.dirname(__FILE__)] + "spec_document.pione"

describe 'Pione::Package::Document' do
  before do
    @env = TestHelper::Lang.env
    @args = ["Test", nil, nil, "spec_document.pione"]
  end

  it 'should load a document from a file' do
    Package::Document.load(@env, document_location, *@args)
    @env.rule_get(Lang::RuleExpr.new("Main")).should.kind_of Lang::RuleDefinition
    @env.rule_get(Lang::RuleExpr.new("RuleA")).should.kind_of Lang::RuleDefinition
    @env.rule_get(Lang::RuleExpr.new("RuleB")).should.kind_of Lang::RuleDefinition
    @env.rule_get(Lang::RuleExpr.new("RuleC")).should.kind_of Lang::RuleDefinition
  end

  it 'should load a document from a string' do
    Package::Document.load(@env, document_location.read, *@args)
    @env.rule_get(Lang::RuleExpr.new("Main")).should.kind_of Lang::RuleDefinition
    @env.rule_get(Lang::RuleExpr.new("RuleA")).should.kind_of Lang::RuleDefinition
    @env.rule_get(Lang::RuleExpr.new("RuleB")).should.kind_of Lang::RuleDefinition
    @env.rule_get(Lang::RuleExpr.new("RuleC")).should.kind_of Lang::RuleDefinition
  end

  it 'should have document parameters' do
    Package::Document.load(@env, document_location, *@args)
    definition = @env.package_get(Lang::PackageExpr.new(package_id: "Test"))
    definition.param_definition["P1"].value.should == Lang::StringSequence.of("a")
    definition.param_definition["P2"].value.should == Lang::StringSequence.of("b")
    definition.param_definition["P3"].value.should == Lang::StringSequence.of("c")
    definition.param_definition["P4"].value.should == Lang::StringSequence.of("d")
    definition.param_definition["P5"].value.should == Lang::StringSequence.of("e")
    definition.param_definition.should.not.has_key("P6")
    definition.param_definition.should.not.has_key("X")
  end

  it 'should have document variable bindings' do
    Package::Document.load(@env, document_location, *@args)
    @env.variable_get(Lang::Variable.new("X")).should == TestHelper::Lang.expr("1")
  end

  it 'should raise variable binding error' do
    should.raise(Lang::RebindError) do
      Package::Document.parse(<<-PIONE, *@args).eval(@env)
        $X := 1
        $X := 2
      PIONE
    end
  end
end
