require 'pione/test-util'
require 'yaml'

class TestParser < Parslet::Parser
  include Pione::Parser::FeatureExpr
end

describe 'Parser::FeatureExpr' do
  describe 'feature_expr' do
    it 'should parse feature expressions' do
      strings = ['+A', '-A', '?A', '(+A)',
                 '+A & +A', '+A | +A', '?A & +A',
                 '(+A) & (+A)', '(+A | +A)',
                 '+A & (+A & -A)', '(+A & -A) & +A']
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.feature_expr.parse(s)
        end
      end
    end

    it 'should parse feature expressions' do
      testcases = YAML.load(File.read(File.join(File.dirname(__FILE__),
                                                "spec_feature-expr",
                                                "spec_feature-expr.yml")))
      testcases.each do |_, testcase|
        p testcase
        tree = TestParser.new.feature_expr.parse(testcase["string"])
        tree.should == testcase["tree"]
      end
    end

    it 'should fail with other strings' do
      strings = ['A', '(-A', '?A)']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.feature_expr.parse(s)
        end
      end
    end
  end
end
