require_relative '../test-util'

document_location = Location[File.dirname(__FILE__)] + "spec_document.pione"

describe 'Pione::Component::Document' do
  before do
    @document = Component::Document.load(document_location)
  end

  it 'should load a document from a file' do
    @document.rules.map{|rule| rule.name}.tap do |x|
      x.should.include "Main"
      x.should.include "RuleA"
      x.should.include "RuleB"
      x.should.include "RuleC"
    end
  end

  it 'should load a document from a string' do
    Component::Document.load(document_location.read).should == @document
  end

  it 'should load a document with package name' do
    document = Component::Document.load(document_location, "Test")
    document.package_name.should == "Test"
    document.find("Main").package_name == "Test"
  end

  it 'should get rule by name' do
    @document.find("Main").should.kind_of(Component::FlowRule)
    @document.find("RuleA").should.kind_of(Component::ActionRule)
    @document.find("RuleB").should.kind_of(Component::ActionRule)
    @document.find("RuleC").should.kind_of(Component::ActionRule)
  end

  it 'should have document parameters' do
    @document.params["P1"].should == PioneString.new("a").to_seq
    @document.params["P2"].should == PioneString.new("b").to_seq
    @document.params["P3"].should == PioneString.new("c").to_seq
    @document.params["P4"].should == PioneString.new("d").to_seq
    @document.params["P5"].should == PioneString.new("e").to_seq
    @document.params["P6"].should == PioneString.new("f").to_seq
    user_params = @document.params.data.select{|var, val| var.user_param}.map{|var, val| var.name}
    user_params.sort.should == ["P1", "P2", "P3", "P4", "P5"]
  end

  it 'should have document variable bindings' do
    @document.find("Main").condition.params["X"].should == 1.to_pione.to_seq
    @document.find("RuleA").condition.params["X"].should == 1.to_pione.to_seq
    @document.find("RuleB").condition.params["X"].should == 1.to_pione.to_seq
    @document.find("RuleC").condition.params["X"].should == 1.to_pione.to_seq
  end

  it 'should create root rule' do
    root = @document.create_root_rule(@document.find("Main"), Model::Parameters.empty)
    root.should.kind_of(Component::RootRule)
  end

  it 'should raise variable binding error' do
    should.raise(VariableBindingError) do
      Component::Document.load <<-PIONE
        $X := 1
        $X := 2
      PIONE
    end
  end
end
