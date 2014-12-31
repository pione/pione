require 'pione/test-helper'

describe Pione::PNML::Perspective do
  def test(name, args, expected)
    env = Lang::Environment.new
    PNML::Perspective.send(name, env, *args).should == expected
  end

  def test_place(name, label, expected)
    test(name, [PNML::Place.new(name: label)], expected)
  end

  def test_transition(name, label, expected)
    test(name, [PNML::Transition.new(name: label)], expected)
  end

  it "should be empty places" do
    test_place(:empty?, "", true)
    test_place(:empty?, "   ", true)
    test_place(:empty?, ">", true)
    test_place(:empty?, " > ", true)
    test_place(:empty?, "# abc", true)
    test_place(:empty?, " # a # b # c", true)
  end

  it "should be empty transitions" do
    test_transition(:empty?, "", true)
    test_transition(:empty?, "   ", true)
    test_transition(:empty?, "# abc", true)
    test_transition(:empty?, " # a # b # c", true)
  end

  it "should be data places" do
    test_place(:data_place?, "'*.a'", true)
    test_place(:data_place?, "'*.a' # abc", true)
    test_place(:data_place?, "<'*.a'", true)
    test_place(:data_place?, "<'*.a' # abc", true)
    test_place(:data_place?, ">'*.a'", true)
    test_place(:data_place?, ">'*.a' # abc", true)
  end

  it "should be net input data places" do
    test_place(:net_input_data_place?, "'*.a'", false)
    test_place(:net_input_data_place?, "'*.a' # abc", false)
    test_place(:net_input_data_place?, "<'*.a'", true)
    test_place(:net_input_data_place?, "<'*.a' # abc", true)
    test_place(:net_input_data_place?, ">'*.a'", false)
    test_place(:net_input_data_place?, ">'*.a' # abc", false)
  end
end

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
      rule.params << PNML::Param.set_of(PNML::Place.new(name: "{X: 1}"))
      rule.as_declaration.should == "rule R {X: 1}"
    end

    PNML::ConstituentRule.new(:action, "R").tap do |rule|
      rule.params << PNML::Param.set_of(PNML::Place.new(name: "{X: 1}"))
      rule.params << PNML::Param.set_of(PNML::Place.new(name: '{Y: "abc"}'))
      rule.as_declaration.should == 'rule R {X: 1, Y: "abc"}'
    end
  end
end

describe Pione::PNML::Data do
  it "should get input declaration string" do
    PNML::InputData.new(PNML::Place.new(name: "'a.txt'")).tap do |cond|
      cond.as_declaration.should == "input 'a.txt'"
    end

    PNML::InputData.new(PNML::Place.new(name: "'a.txt' | 'b.txt' | 'c.txt'")).tap do |cond|
      cond.as_declaration.should == "input 'a.txt' | 'b.txt' | 'c.txt'"
    end

    PNML::InputData.new(PNML::Place.new(name: "'a.txt'")).tap do |cond|
      cond.input_nonexistable = true
      cond.as_declaration.should == "input 'a.txt' or null"
    end

    PNML::InputData.new(PNML::Place.new(name: "'*.txt'")).tap do |cond|
      cond.as_declaration.should == "input '*.txt'"
    end

    PNML::InputData.new(PNML::Place.new(name: "'a.txt'")).tap do |cond|
      cond.input_distribution = :all
      cond.as_declaration.should == "input ('a.txt').all"
    end

    PNML::InputData.new(PNML::Place.new(name: "'a.txt' #100")).tap do |cond|
      cond.priority.should == 100
      cond.as_declaration.should == "input 'a.txt'"
    end
  end

  it "should get output declaration string" do
    PNML::OutputData.new(PNML::Place.new(name: "'a.txt'")).tap do |cond|
      cond.as_declaration.should == "output 'a.txt'"
    end

    PNML::OutputData.new(PNML::Place.new(name: "'*.txt'")).tap do |cond|
      cond.as_declaration.should == "output '*.txt'"
    end

    PNML::OutputData.new(PNML::Place.new(name: "'a.txt' | 'b.txt' | 'c.txt'")).tap do |cond|
      cond.as_declaration.should == "output 'a.txt' | 'b.txt' | 'c.txt'"
    end

    PNML::OutputData.new(PNML::Place.new(name: "'a.txt'")).tap do |cond|
      cond.output_nonexistable = true
      cond.as_declaration.should == "output 'a.txt' or null"
    end

    PNML::OutputData.new(PNML::Place.new(name: "'a.txt'")).tap do |cond|
      cond.output_distribution = :all
      cond.as_declaration.should == "output ('a.txt').all"
    end

    PNML::OutputData.new(PNML::Place.new(name: "'a.txt' #100")).tap do |cond|
      cond.priority.should == 100
      cond.as_declaration.should == "output 'a.txt'"
    end
  end
end

describe Pione::PNML::Param do
  it "should create parameter from param sentence node" do
    PNML::Param.sentence_of(PNML::Place.new(name: "param $X := 1")).tap do |param|
      param.data.should == {"X" => "1"}
    end
  end

  it "should create parameter from param set node" do
    PNML::Param.set_of(PNML::Place.new(name: "{X: 1}")).tap do |param|
      param.data.should == {"X" => "1"}
    end

    PNML::Param.set_of(PNML::Place.new(name: "{X: 1, Y: 2, Z: 3}")).tap do |param|
      param.data.should == {"X" => "1", "Y" => "2", "Z" => "3"}
    end
  end

  it "should get expression strings" do
    PNML::Param.set_of(PNML::Place.new(name: "{X: 1}")).tap do |param|
      param.as_expr.should == "{X: 1}"
    end

    PNML::Param.set_of(PNML::Place.new(name: "{X: 1, Y: 2, Z: 3}")).tap do |param|
      param.as_expr.should == "{X: 1, Y: 2, Z: 3}"
    end
  end

  it "should get declaration strings" do
    PNML::Param.sentence_of(PNML::Place.new(name: "param $X := 1")).tap do |param|
      param.as_declarations.should == ["param $X := 1"]
    end

    PNML::Param.set_of(PNML::Place.new(name: "{X: 1, Y: 2, Z: 3}")).tap do |param|
      param.as_declarations.should == ["param $X := 1", "param $Y := 2", "param $Z := 3"]
    end
  end
end

describe Pione::PNML::ConditionalBranch do
  it "should get declaration string" do
    PNML::ConditionalBranch.new(:case, "$X").tap do |cb|
      cb.table["true"] << PNML::ConstituentRule.new(:action, "R1")
      cb.table["false"] << PNML::ConstituentRule.new(:action, "R2")
      cb.as_declaration.should == Util::Indentation.cut(<<-PIONE)
        case $X
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
