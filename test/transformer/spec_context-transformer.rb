require_relative '../test-util'

describe 'Pione::Transformer::ContextTransformer' do
  transformer_spec("structural_context", :structural_context) do
    test "$X := 1" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::VariableBindingDeclaration
    end

    test "package $P <- &Package" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::PackageBindingDeclaration
    end

    test "param $X" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::ParamDeclaration
    end

    test "rule A := B" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::RuleBindingDeclaration
    end

    test "rule A" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::ConstituentRuleDeclaration
    end

    test "input '*.txt'" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::InputDeclaration
    end

    test "output '*.txt'" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::OutputDeclaration
    end

    test "feature +X" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::FeatureDeclaration
    end

    test "constraint $X.odd?" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::ConstraintDeclaration
    end

    test "? 1 + 1" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::ExprDeclaration
    end

    test "Param; $X := 1; $Y := 2; End" do |context|
      context.size.should == 1
      context[0].should.kind_of Lang::ParamBlockDeclaration
    end

    test(<<-STRING) do |context|
      Rule A
        input '*.a'
        output '*.b'
      Flow
        rule B
      End
    STRING
      context.size.should == 1
      context[0].should.kind_of Lang::FlowRuleDeclaration
    end

    test(<<-STRING) do |context|
      Rule A
        input '*.a'
        output '*.b'
      Action
        cat {$I[1]} > {$O[1]}
      End
    STRING
      context.size.should == 1
      context[0].should.kind_of Lang::ActionRuleDeclaration
    end

    test(<<-STRING) do |context|
      Rule A
        input '*.a'
        output '*.b'.touch
      End
    STRING
      context.size.should == 1
      context[0].should.kind_of Lang::EmptyRuleDeclaration
    end

    # with elements
    test "input '*.a'; output '*.b'" do |context|
      context.size.should == 2
      context[0].should.kind_of Lang::InputDeclaration
      context[1].should.kind_of Lang::OutputDeclaration
    end
  end

  transformer_spec("conditional_branch_context", :conditional_branch_context) do
    # accept all declaration
    succeed "$X := 1"
    succeed "package $P <- &Package"
    fail "param $X", Lang::ContextError
    succeed "rule A := B"
    succeed "rule A"
    succeed "input '*.txt'"
    succeed "output '*.txt'"
    succeed "feature +X"
    succeed "constraint $X.odd?"
    succeed "? 1 + 1"
    fail "Param; $X := 1; $Y := 2; End", Lang::ContextError
    succeed <<-STRING
      Rule A
        input '*.a'
        output '*.b'
      Flow
        rule B
      End
    STRING
    succeed <<-STRING
      Rule A
        input '*.a'
        output '*.b'
      Action
        cat {$I[1]} > {$O[1]}
      End
    STRING
    succeed <<-STRING
      Rule A
        input '*.a'
        output '*.b'.touch
      End
    STRING
    succeed <<-STRING
      if true
        $X := 1
      end
    STRING
    succeed <<-STRING
      case $X
      when "A"
        rule A
      when "B"
        rule B
      when "C"
        rule C
      end
    STRING
  end

  transformer_spec("param_context", :param_context) do
    succeed "$X := 1"
    fail "package $P <- &Package", Lang::ContextError
    fail "param $X", Lang::ContextError
    fail "rule A := B", Lang::ContextError
    fail "rule A", Lang::ContextError
    fail "input '*.txt'", Lang::ContextError
    fail "output '*.txt'", Lang::ContextError
    fail "feature +X", Lang::ContextError
    fail "constraint $X.odd?", Lang::ContextError
    succeed "? 1 + 1"
    fail "Param; $X := 1; $Y := 2; End", Lang::ContextError
    fail <<-STRING, Lang::ContextError
      Rule A
        input '*.a'
        output '*.b'
      Flow
        rule B
      End
    STRING
    fail <<-STRING, Lang::ContextError
      Rule A
        input '*.a'
        output '*.b'
      Action
        cat {$I[1]} > {$O[1]}
      End
    STRING
    fail <<-STRING, Lang::ContextError
      Rule A
        input '*.a'
        output '*.b'.touch
      End
    STRING
  end

  transformer_spec("action_context", :action_context) do
    test(<<-STRING) do |context|
      echo "a"
    STRING
      context.should.kind_of Lang::ActionContext
      context.string.should == "echo \"a\"\n"
    end

    test(<<-STRING) do |context|
      This is a line.
      This is a line, too.
    STRING
      context.should.kind_of Lang::ActionContext
      context.string.should == "This is a line.\nThis is a line, too.\n"
    end
  end
end
