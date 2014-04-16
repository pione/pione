require 'pione/test-helper'

describe Pione::PNML::ConstituentRule do
  it "should get declaration string" do
    PNML::ConstituentRule.new(:action, "R").tap do |rule|
      rule.as_declaration.should == "rule R"
    end

    PNML::ConstituentRule.new(:flow, "R").tap do |rule|
      rule.as_declaration.should == "rule R"
    end

    PNML::ConstituentRule.new(:action, "$P.rule(R)").tap do |rule|
      rule.as_declaration.should == "rule $P.rule(R)"
    end

    PNML::ConstituentRule.new(:action, "R").tap do |rule|
      rule.params << PNML::Param.new("x", "1")
      rule.as_declaration.should == "rule R {x: $x}"
    end

    PNML::ConstituentRule.new(:action, "R").tap do |rule|
      rule.params << PNML::Param.new("x", "1")
      rule.params << PNML::Param.new("y", '"abc"')
      rule.as_declaration.should == 'rule R {x: $x, y: $y}'
    end
  end
end

describe Pione::PNML::DataCondition do
  it "should get input declaration string" do
    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.as_input_declaration.should == "input 'a.txt'"
    end

    PNML::DataCondition.new("'a.txt' | 'b.txt' | 'c.txt'").tap do |cond|
      cond.as_input_declaration.should == "input 'a.txt' | 'b.txt' | 'c.txt'"
    end

    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.input_nonexistable = true
      cond.as_input_declaration.should == "input 'a.txt' or null"
    end

    PNML::DataCondition.new("'*.txt'").tap do |cond|
      cond.as_input_declaration.should == "input '*.txt'"
    end

    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.input_distribution = :all
      cond.as_input_declaration.should == "input ('a.txt').all"
    end

    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.input_priority = 100
      cond.as_input_declaration.should == "input 'a.txt'"
    end
  end

  it "should get output declaration string" do
    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.as_output_declaration.should == "output 'a.txt'"
    end

    PNML::DataCondition.new("'*.txt'").tap do |cond|
      cond.as_output_declaration.should == "output '*.txt'"
    end

    PNML::DataCondition.new("'a.txt' | 'b.txt' | 'c.txt'").tap do |cond|
      cond.as_output_declaration.should == "output 'a.txt' | 'b.txt' | 'c.txt'"
    end

    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.output_nonexistable = true
      cond.as_output_declaration.should == "output 'a.txt' or null"
    end

    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.output_distribution = :all
      cond.as_output_declaration.should == "output ('a.txt').all"
    end

    PNML::DataCondition.new("'a.txt'").tap do |cond|
      cond.output_priority = 100
      cond.as_output_declaration.should == "output 'a.txt'"
    end
  end
end

describe Pione::PNML::Param do
  it "should get declaration string" do
    PNML::Param.new("x", "1").tap do |param|
      param.as_declaration.should == "param $x := 1"
    end
  end
end

describe Pione::PNML::ConditionalBranch do
  it "should get declaration string" do
    PNML::ConditionalBranch.new(:case, "$x").tap do |cb|
      cb.table["true"] << PNML::ConstituentRule.new(:action, "R1")
      cb.table["false"] << PNML::ConstituentRule.new(:action, "R2")
      cb.as_declaration.should == Util::Indentation.cut(<<-PIONE)
        case $x
        when true
          rule R1
        when false
          rule R2
        end
      PIONE
    end

    PNML::ConditionalBranch.new(:case, "$x").tap do |cb|
      cb.table["true"] << PNML::ConstituentRule.new(:action, "R1")
      cb.table["true"] << PNML::ConstituentRule.new(:action, "R2")
      cb.table["true"] << PNML::ConstituentRule.new(:action, "R3")
      cb.table["false"] << PNML::ConstituentRule.new(:action, "R4")
      cb.table["false"] << PNML::ConstituentRule.new(:action, "R5")
      cb.table["false"] << PNML::ConstituentRule.new(:action, "R6")
      cb.as_declaration.should == Util::Indentation.cut(<<-PIONE)
        case $x
        when true
          rule R1
          rule R2
          rule R3
        when false
          rule R4
          rule R5
          rule R6
        end
      PIONE
    end

    PNML::ConditionalBranch.new(:case, "$x").tap do |cb|
      cb.table["true"] << PNML::ConstituentRule.new(:action, "R1")
      cb.as_declaration.should == Util::Indentation.cut(<<-PIONE)
        case $x
        when true
          rule R1
        end
      PIONE
    end
  end
end
