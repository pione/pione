require 'pione/test-util'

describe 'Transformer::FlowElement' do
  it 'should get a CallRule' do
    string = "rule Test"
    tree = Parser.new.call_rule_line.parse(string)
    res = Transformer.new.apply(tree)
    res.should.kind_of(Rule::FlowElement::CallRule)
    res.expr.should == RuleExpr.new("Test")
  end

  it 'should get a IfBlock' do

  end
end
