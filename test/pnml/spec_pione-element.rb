require 'pione/test-helper'

describe Pione::PNML::Perspective do
  it "should be empty places" do
    env = Lang::Environment.new
    ["", "   ", ">", " > ", "# abc", " # a # b # c"].each do |label|
      PNML::Perspective.empty?(env, PNML::Place.new(name: label)).should.true
    end
  end

  it "should be empty transitions" do
    env = Lang::Environment.new
    ["", "   ", "# abc", " # a # b # c"].each do |label|
      PNML::Perspective.empty?(env, PNML::Transition.new(name: label)).should.true
    end
  end

  it "should be data places" do
    env = Lang::Environment.new
    [ "'*.a'",
      "'*.a' # abc",
      "<'*.a'",
      "<'*.a' # abc",
      ">'*.a'",
      ">'*.a' # abc"
    ].each do |label|
      PNML::Perspective.data_place?(env, PNML::Place.new(name: label)).should.true
    end
  end

  it "should be net input data places" do
    f = lambda {|labe, re|
      env = Lang::Environment.new
      PNML::Perspective.net_input_data_place?(env, PNML::Place.new(name: labe)).should == re
    }

    f.call("'*.a'", false)
    f.call("'*.a' # abc", false)
    f.call("<'*.a'", true)
    f.call("<'*.a' # abc", true)
    f.call(">'*.a'", false)
    f.call(">'*.a' # abc", false)
  end
end

describe Pione::PNML::LabelExtractor do
  it "should extract rule expressions" do
    { "A" => "A",
      "A # abc" => "A",
      "A # a # b # c" => "A",
      "A {X: 1}" => "A {X: 1}",
      "extern A" => "A",
      "extern A {X: 1}" => "A {X: 1}"
    }.each do |label, expr|
      PNML::LabelExtractor.extract_rule_expr(label).should == expr
    end
  end

  it "sohuld extract data expressions" do
    { "'*.a'" => "'*.a'",
      "'*.a' # abc" => "'*.a'",
      "'#.a' # abc" => "'#.a'",
      "'*.a' # a # b # c" => "'*.a'",
      "< '*.a'" => "'*.a'",
      "< '*.a' # abc" => "'*.a'",
      "> '*.a'" => "'*.a'",
      "> '*.a' # abc" => "'*.a'"
    }.each do |label, expr|
      PNML::LabelExtractor.extract_data_expr(label).should == expr
    end
  end

  it "should extract param set expressions" do
    { "{X: 1}" => "{X: 1}",
      "{X: 1} # abc" => "{X: 1}",
      "{X: 1, Y: 2, Z: 3}" => "{X: 1, Y: 2, Z: 3}",
      "{X: 1, Y: 2, Z: 3} # abc" => "{X: 1, Y: 2, Z: 3}"
    }.each do |label, expr|
      PNML::LabelExtractor.extract_param_set(label).should == expr
    end
  end

  it "should extract ticket expressions" do
    { "<T>" => "<T>",
      "<T> # abc" => "<T>"
    }.each do |label, expr|
      PNML::LabelExtractor.extract_ticket(label).should == expr
    end
  end

  it "should extract feature expressions" do
    { "+X" => "+X",
      "-X" => "-X",
      "!X" => "!X",
      "?X" => "?X",
      "+X # abc" => "+X",
      "-X # abc" => "-X",
      "!X # abc" => "!X",
      "?X # abc" => "?X",
    }.each do |label, expr|
      PNML::LabelExtractor.extract_feature(label).should == expr
    end
  end

  it "should extract parameter sentences" do
    { "param $X" => "param $X",
      "param $X := 1" => "param $X := 1",
      "basic param $X" => "basic param $X",
      "advanced param $X" => "advanced param $X",
      "param $X # abc" => "param $X",
      "param $X := 1 # abc" => "param $X := 1",
    }.each do |label, expr|
      PNML::LabelExtractor.extract_param_sentence(label).should == expr
    end
  end

  it "should extract feature sentences" do
    { "feature +X" => "feature +X",
      "feature -X" => "feature -X",
      "feature !X" => "feature !X",
      "feature ?X" => "feature ?X",
      "feature +X # abc" => "feature +X",
      "feature -X # abc" => "feature -X",
      "feature !X # abc" => "feature !X",
      "feature ?X # abc" => "feature ?X",
    }.each do |label, expr|
      PNML::LabelExtractor.extract_feature_sentence(label).should == expr
    end
  end

  it "should extract variable binding sentences" do
    { "$X := 1" => "$X := 1",
      "$X := 1 # abc" => "$X := 1",
      '$X := "# abc" # abc' => '$X := "# abc"',
    }.each do |label, expr|
      PNML::LabelExtractor.extract_feature_sentence(label).should == expr
    end
  end

  it "should extract priority" do
    { "'*.a' #1" => 1,
      "'*.a' #2" => 2,
      "'*.a' #3" => 3,
      "'*.a' #1 # abc" => 1,
      "'#1' #1000" => 1000,
      "'*.a'" => nil,
    }.each do |label, priority|
      PNML::LabelExtractor.extract_priority(label).should == priority
    end
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
