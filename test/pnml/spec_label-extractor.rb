require 'pione/test-helper'

describe Pione::PNML::LabelExtractor do
  def extract(name, label, expected)
    PNML::LabelExtractor.send(name, label).should == expected
  end

  it "should extract rule expressions" do
    extract(:extract_rule_expr, "A", "A")
    extract(:extract_rule_expr, "A # abc", "A")
    extract(:extract_rule_expr, "A # a # b # c", "A")
    extract(:extract_rule_expr, "A {X: 1}", "A {X: 1}")
    extract(:extract_rule_expr, "extern A", "A")
    extract(:extract_rule_expr, "extern A {X: 1}", "A {X: 1}")
  end

  it "sohuld extract data expressions" do
    extract(:extract_data_expr, "'*.a'", "'*.a'")
    extract(:extract_data_expr, "'*.a' # abc", "'*.a'")
    extract(:extract_data_expr, "'#.a' # abc", "'#.a'")
    extract(:extract_data_expr, "'*.a' # a # b # c", "'*.a'")
    extract(:extract_data_expr, "< '*.a'", "'*.a'")
    extract(:extract_data_expr, "< '*.a' # abc", "'*.a'")
    extract(:extract_data_expr, "> '*.a'", "'*.a'")
    extract(:extract_data_expr, "> '*.a' # abc", "'*.a'")
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
    extract(:extract_feature_sentence, "feature +X", "feature +X")
    extract(:extract_feature_sentence, "feature -X", "feature -X")
    extract(:extract_feature_sentence, "feature !X", "feature !X")
    extract(:extract_feature_sentence, "feature ?X", "feature ?X")
    extract(:extract_feature_sentence, "feature +X # abc", "feature +X")
    extract(:extract_feature_sentence, "feature -X # abc", "feature -X")
    extract(:extract_feature_sentence, "feature !X # abc", "feature !X")
    extract(:extract_feature_sentence, "feature ?X # abc", "feature ?X")
  end

  it "should extract variable binding sentences" do
    extract(:extract_variable_binding, "$X := 1", "$X := 1")
    extract(:extract_variable_binding, "$X := 1 # abc", "$X := 1")
    extract(:extract_variable_binding, '$X := "# abc" # abc', '$X := "# abc"')
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
