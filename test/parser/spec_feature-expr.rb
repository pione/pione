require 'innocent-white/test-util'

class TestParser < Parslet::Parser
  include InnocentWhite::Parser::FeatureExpr
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
