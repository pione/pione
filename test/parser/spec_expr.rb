require 'pione/test-util'

class TestParser < Parslet::Parser
  include Pione::Parser::Expr
end

describe 'Parser::Expr' do
  testcases = YAML.load(File.read(File.join(File.dirname(__FILE__),
                                            "spec_expr.yml")))
  testcases.each do |name, data|
    parser = TestParser.new.send(name.to_sym)

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
            parser.parse(string)
          end
        end
      end
    end
  end
end

