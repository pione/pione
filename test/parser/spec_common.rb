# -*- coding: utf-8 -*-
require 'innocent-white/test-util'

class TestParser < Parslet::Parser
  include InnocentWhite::Parser::Common

  rule(:test_line_end) {
    str('begin') >> line_end >> str('end')
  }

  rule(:test_empty_lines_1) {
    str('begin') >> empty_lines >> str('end')
  }

  rule(:test_empty_lines_2) {
    str('begin') >> empty_lines? >> str('end')
  }

  rule(:test_empty_lines_3) {
    (str('item') >> empty_lines).repeat
  }

  rule(:test_empty_lines_4) {
    (str('item') >> empty_lines?).repeat
  }
end

describe 'Parser::Common' do
  describe 'symbols' do
    it 'should parse symbols' do
      Parser::Common::SYMBOLS.values.each do |val|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.symbols.parse(val)
        end
      end
    end

    it 'should fail with other characters' do
      ('a'..'z').each do |val|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.symbols.parse(val)
        end
      end
    end
  end

  describe 'keywords' do
    it 'should parse keywords' do
      Parser::Common::KEYWORDS.each do |key, val|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.send(key).parse(val)
        end
      end
    end

    it 'should fail with other words' do
      words = ['abc', '', 'RULE', 'enD', 'Input']
      Parser::Common::KEYWORDS.keys.each do |key|
        words.each do |word|
          should.raise(Parslet::ParseFailed) do
            TestParser.new.send(key).parse(word)
          end
        end
      end
    end
  end

  describe 'digit' do
    it 'should parse digit' do
      (0..9).each do |n|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.digit.parse(n.to_s)
        end
      end
    end

    it 'should fail with number sequences' do
      (10..100).each do |n|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.digit.parse(n.to_s)
        end
      end
    end

    it 'should fail with other characters' do
      ('a'..'z').each do |char|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.digit.parse(char)
        end
      end
    end
  end

  describe 'space / space?' do
    it 'should parse space string' do
      strings = [' ', '  ', "\t", "\t\t", " \t ", "\t \t"]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.space.parse(s)
        end

        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.space?.parse(s)
        end
      end
    end

    it 'should fail with other characters' do
      strings = [' a ', "\n", "abc", '　']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.space.parse(s)
        end

        should.raise(Parslet::ParseFailed) do
          TestParser.new.space?.parse(s)
        end
      end
    end

    it 'should get different results with empty string' do
      should.raise(Parslet::ParseFailed) do
        TestParser.new.space.parse("")
      end

      should.not.raise(Parslet::ParseFailed) do
        TestParser.new.space?.parse("")
      end
    end
  end

  describe 'line_end' do
    it 'should parse line ended string' do
      strings = ['', ' ', '  ', "  \n"]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.line_end.parse(s)
        end
      end
    end

    it 'should fail with other string' do
      strings = ['a', ' a', '  _', '   1', "  \n "]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.line_end.parse(s)
        end
      end
    end

    it 'should succeed in test_line_end' do
      strings = ["begin\nend", "begin \nend", "begin \t\nend"]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.test_line_end.parse(s)
        end
      end
    end

    it 'should fail in test_line_end' do
      strings = ["beginend", "begin\n end", "begin\n\nend"]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.test_line_end.parse(s)
        end
      end
    end
  end

  describe 'empty_lines / empty_lines?' do
    it 'should parse empty lines' do
      strings = ["\n", "\n\n", " \n ", "\n \n", " \n \n "]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.empty_lines.parse(s)
        end

        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.empty_lines?.parse(s)
        end
      end
    end

    it 'should fail with other string' do
      strings = ['a', ' a', '  _', '   1']
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.empty_lines.parse(s)
        end

        should.raise(Parslet::ParseFailed) do
          TestParser.new.empty_lines?.parse(s)
        end
      end
    end

    it 'should get different results whether empty_line or empty_line?' do
      should.raise(Parslet::ParseFailed) do
        TestParser.new.empty_lines.parse("")
      end

      should.not.raise(Parslet::ParseFailed) do
        TestParser.new.empty_lines?.parse("")
      end
    end

    it 'should succeed in test_empty_lines_1' do
      strings = ["begin\n\nend", "begin \nend", "begin\n\nend"]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_1.parse(s)
        end
      end
    end

    it 'should fail in test_empty_lines_1' do
      strings = ["beginend", "begin end", "begin\n end", "begin\na\nend"]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_1.parse(s)
        end
      end
    end

    it 'should suceed in test_empty_lines_2' do
      strings = ["begin\n\nend", "begin \nend", "begin\n\nend", "beginend"]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_2.parse(s)
        end
      end
    end

    it 'should fail in test_empty_lines_2' do
      strings = ["begin end", "begin\n end", "begin\na\nend"]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_2.parse(s)
        end
      end
    end

    it 'should suceed in test_empty_lines_3' do
      strings = ["item\n", "item \n", "item\n ",
                 "item\n\nitem\n", "item \nitem \n "]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_3.parse(s)
        end
      end
    end

    it 'should fail in test_empty_lines_3' do
      strings = ["item", "item\nitem", "itemitem", "item item"]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_3.parse(s)
        end
      end
    end

    it 'should suceed in test_empty_lines_4' do
      strings = ["item", "item\n", "item \n", "item\n ", "itemitem",
                 "item\nitem", "item\n\nitem\n", "item \nitem \n "]
      strings.each do |s|
        should.not.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_4.parse(s)
        end
      end
    end

    it 'should fail in test_empty_lines_4' do
      strings = [ "item item", "item " ]
      strings.each do |s|
        should.raise(Parslet::ParseFailed) do
          TestParser.new.test_empty_lines_4.parse(s)
        end
      end
    end
  end
end
