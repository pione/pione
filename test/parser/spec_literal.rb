# -*- coding: utf-8 -*-
require 'pione/test-util'

class TestParser < Parslet::Parser
  include Pione::Parser::Literal
end

describe 'Parser::Literal' do
  describe 'data_name' do
    it 'should parse data names' do
      strings = ["''", "'test'", "'(test)'", "'test*'",
               "'日本語'", "'\\a'", "'\\\\a'"]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.data_name.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ["test", "'test", "test'", "'\\'", "\\''"]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.data_name.parse(s)
        end
      end
    end
  end

  describe 'identifier' do
    it 'should parse identifiers' do
      strings = ['a', 'A', 'a_b', '_a', '日本語', '_']
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.identifier.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ['$a', '"a"', "'a'", ' ', "\n"]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.identifier.parse(s)
        end
      end
    end
  end

  describe 'variable' do
    it 'should parse variables' do
      strings = ['$a', '$abc', '$a_b', '$a0', '$0', '$A', '$AA', '$日本語']
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.variable.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ['$', '$ ', 'a', '', '$$', '$+', '$-']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.variable.parse(s)
        end
      end
    end
  end

  describe 'rule_name' do
    it 'should parse rule names' do
      strings = ['Main', '/Main', '/A/B', 'A/B', '日本語', 'a']
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.rule_name.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ['/Main/', 'Main/', '//Main', '', '/', '//']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.rule_name.parse(s)
        end
      end
    end
  end

  describe 'feature_name' do
    it 'should parse rule names' do
      #strings = ['+ABC', '-ABC', '?ABC', '+日本語', '-日本語', '?日本語']
      testcases =
        [ { :string => '+ABC',
            :tree => {:feature_name => "ABC", :type => 'positive'} },
          { :string => '-ABC',
            :tree => {:feature_name => 'ABC', :type => 'negative'} },
          { :string => '?ABC',
            :tree => {:feature_name => 'ABC', :type => 'preferred'} },
          { :string => '+日本語',
            :tree => {:feature_name => '日本語', :type => 'positive'} },
          { :string => '-日本語',
            :tree => {:feature_name => '日本語', :type => 'negative'} },
          { :string => '?日本語',
            :tree => {:feature_name => '日本語', :type => 'preferred'} } ]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.feature_name.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ['', '+', '-', '?', '++', '--', '??']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.feature_name.parse(s)
        end
      end
    end
  end

  describe 'string' do
    it 'should parse strings' do
      strings = ['""', '"test"', '"(test)"', '"test*"', '"日本語"', '"\a"']
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.string.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ['test', 'test"', '"test', '"\"', '\""', '"" ']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.string.parse(s)
        end
      end
    end
  end

  describe 'integer' do
    it 'should parse integers' do
      strings = ['1', '123', '01', '+1', '+01', '-1', '-01', '+0', '-0']
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.integer.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ['-', '+', '', '0.1', '.1', '1a', 'a1']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.integer.parse(s)
        end
      end
    end
  end

  describe 'float' do
    it 'should parse floats' do
      strings = ['0.1', '1.0', '01.0', '+1.0', '+01.1',
                 '-1.0', '-01.0', '+0.0', '-0.0']
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.float.parse(s)
        end
      end
    end

    it 'should fail with other strings' do
      strings = ['-1', '+1', '', '.1', '0.1a', '0.a1']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.float.parse(s)
        end
      end
    end
  end
end
