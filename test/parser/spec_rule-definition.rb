require 'pione/test-util'

class TestParser < Parslet::Parser
  include Pione::Parser::RuleDefinition
end

testcases = YAML.load(File.read(File.join(File.dirname(__FILE__),
                                          "spec_rule-definition.yml")))

testcases.each do |name, data|
  parser = TestParser.new.send(name.to_sym)
  describe(name) do
    if strings = data["valid"]
      strings.each_with_index do |string, i|
        it "should parse as #{name}: #{i}" do
          should.not.raise(Parslet::ParseFailed) do
            parser.parse(string)
          end
        end
      end
    end

    if strings = data["invalid"]
      strings.each_with_index do |string, i|
        it "should fail when parsing as #{name}: #{i}" do
          should.raise(Parslet::ParseFailed) do
            p parser.parse(string)
          end
        end
      end
    end
  end
end
