require 'pione/test-helper'

describe Pione::LiterateAction::MarkdownParser do
  it "should parse" do
    parsed = LiterateAction::MarkdownParser.parse(Util::Indentation.cut(<<-ACTION))
      # Titile

      desc

      ## Name1

      desc

      ```sh
      A
      ```

      ## Name2

      desc1

      ```ruby
      A
      ```

      desc2

      ```ruby
      B
      ```
    ACTION
    parsed.keys.sort.should == ["Name1", "Name2"]
    parsed["Name1"][:lang].should == "sh"
    parsed["Name1"][:content].should == "A\n"
    parsed["Name2"][:lang].should == "ruby"
    parsed["Name2"][:content].should == "A\nB\n"
  end

  it "should get a rule name without needless spaces" do
    parsed = LiterateAction::MarkdownParser.parse(Util::Indentation.cut(<<-ACTION))
      # Title

      ##    Test    

      ``` sh
      A
      ```
    ACTION
    parsed.keys.first.should == "Test"
  end
end
