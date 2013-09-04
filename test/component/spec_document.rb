require_relative '../test-util'

document_location = Location[File.dirname(__FILE__)] + "spec_document.pione"

describe 'Pione::Component::Document' do
  before do
    @env = TestUtil::Lang.env
    @opt = {package_name: "Test", filename: "spec_document.pione"}
  end

  it 'should load a document from a file' do
    Component::Document.load(document_location, @opt).eval(@env)
    @env.rule_get(RuleExpr.new("Main")).should.kind_of Lang::RuleDefinition
    @env.rule_get(RuleExpr.new("RuleA")).should.kind_of Lang::RuleDefinition
    @env.rule_get(RuleExpr.new("RuleB")).should.kind_of Lang::RuleDefinition
    @env.rule_get(RuleExpr.new("RuleC")).should.kind_of Lang::RuleDefinition
  end

  it 'should load a document from a string' do
    Component::Document.parse(document_location.read, @opt).eval(@env)
    @env.rule_get(RuleExpr.new("Main")).should.kind_of Lang::RuleDefinition
    @env.rule_get(RuleExpr.new("RuleA")).should.kind_of Lang::RuleDefinition
    @env.rule_get(RuleExpr.new("RuleB")).should.kind_of Lang::RuleDefinition
    @env.rule_get(RuleExpr.new("RuleC")).should.kind_of Lang::RuleDefinition
  end

  it 'should have document parameters' do
    Component::Document.load(document_location, @opt).eval(@env)
    definition = @env.package_get(PackageExpr.new(package_id: "Test"))
    definition.param_definition["P1"].value.should == StringSequence.of("a")
    definition.param_definition["P2"].value.should == StringSequence.of("b")
    definition.param_definition["P3"].value.should == StringSequence.of("c")
    definition.param_definition["P4"].value.should == StringSequence.of("d")
    definition.param_definition["P5"].value.should == StringSequence.of("e")
    definition.param_definition.should.not.has_key("P6")
    definition.param_definition.should.not.has_key("X")
  end

  it 'should have document variable bindings' do
    Component::Document.load(document_location, @opt).eval(@env)
    @env.variable_get(Variable.new("X")).should == TestUtil::Lang.expr("1")
  end

  it 'should raise variable binding error' do
    should.raise(Lang::RebindError) do
      Component::Document.parse(<<-PIONE, @opt).eval(@env)
        $X := 1
        $X := 2
      PIONE
    end
  end
end
