require 'pione/test-util'

describe 'Transformer::FlowElement' do
  it 'should get a CallRule' do
    string = "rule Test"
    tree = Parser.new.call_rule_line.parse(string)
    res = Transformer.new.apply(tree)
    res.should.kind_of(Rule::FlowElement::CallRule)
    res.expr.should == RuleExpr.new("Test")
  end

  it 'should get a ConditionalBlock by if_parse' do
    string = <<-STRING
      if $Var == "a"
        rule A
      else
        rule B
      end
    STRING
    tree = Parser.new.if_block.parse(string)
    res = Transformer.new.apply(tree)
    res.should.kind_of(Rule::FlowElement::ConditionalBlock)
    res.expr.should == Model::BinaryOperator.new("==",
                                                 Variable.new("Var"),
                                                 PioneString.new("a"))
  end

  it 'should get a ConditionalBlock by case_parse' do
    string = <<-STRING
      case $Var
      when "a"
        rule A
      when "b"
        rule B
      when "c"
        rule C
      end
    STRING
    tree = Parser.new.case_block.parse(string)
    res = Transformer.new.apply(tree)
    res.should.kind_of(Rule::FlowElement::ConditionalBlock)
    res.expr.should == Variable.new("Var")
  end
end
