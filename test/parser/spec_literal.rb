# -*- coding: utf-8 -*-
require 'pione/test-util'

class TestParser < Parslet::Parser
  include Pione::Parser::Literal
end

describe 'Parser::Literal' do
  testcases = YAML.load(File.read(File.join(File.dirname(__FILE__),
                                            "spec_literal.yml")))
  testcases.each do |parser, testcase|
    describe "#{parser}" do
      if strings = testcase["valid"]
        strings.each_with_index do |string, i|
          it "should parse as #{parser}: #{string}" do
            should.not.raise(Parslet::ParseFailed) do
              TestParser.new.send(parser).parse(string)
            end
          end
        end
      end
      if strings = testcase["invalid"]
        strings.each_with_index do |string, i|
          it "should fail when parsing as #{parser}: #{string}" do
            should.raise(Parslet::ParseFailed) do
              TestParser.new.send(parser).parse(string)
            end
          end
        end
      end
    end
  end
end
