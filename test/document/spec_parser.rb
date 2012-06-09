# -*- coding: utf-8 -*-
require 'pione/test-util'

describe 'Document::Parser' do
  before do
    @parser = Document::Parser.new
  end

  describe 'data_name' do
    it 'should get a data name' do
      tree = @parser.data_name.parse("'test.a'")
      tree[:data_name].should == "test.a"
    end

    it 'should include symbols' do
      tree = @parser.data_name.parse("'(test).a'")
      tree[:data_name].should == "(test).a"
    end
  end

  describe 'string' do
    it 'should get a string' do
      tree = @parser.string.parse('"string"')
      tree[:string].should == 'string'
    end

    it 'should include symbols' do
      tree = @parser.string.parse('"(string){}"')
      tree[:string].should == '(string){}'
    end
  end

  describe 'integer' do
    it 'should 1' do
      expr = @parser.integer.parse('1')
      expr[:integer].should == "1"
    end

    it 'should 123' do
      expr = @parser.integer.parse('123')
      expr[:integer].should == "123"
    end

    it 'should +1' do
      expr = @parser.integer.parse('+1')
      expr[:integer].should == "+1"
    end

    it 'should -1' do
      expr = @parser.integer.parse('-1')
      expr[:integer].should == "-1"
    end
  end

  describe 'float' do
    it 'should 0.1' do
      expr = @parser.float.parse('0.1')
      expr[:float].should == "0.1"
    end

    it 'should 123.000123' do
      expr = @parser.float.parse('123.000123')
      expr[:float].should == "123.000123"
    end

    it 'should +0.1' do
      expr = @parser.float.parse('+0.1')
      expr[:float].should == "+0.1"
    end

    it 'should -0.1' do
      expr = @parser.float.parse('-0.1')
      expr[:float].should == "-0.1"
    end
  end

  describe 'rule_name' do
    it 'should get a rule name' do
      tree = @parser.rule_name.parse('abc')
      tree[:rule_name].should == 'abc'
    end

    it 'should get a full rule path name' do
      tree = @parser.rule_name.parse('/abc/def/ghi')
      tree[:rule_name].should == '/abc/def/ghi'
    end

    it 'should get a relative rule path name' do
      tree = @parser.rule_name.parse('abc/def/ghi')
      tree[:rule_name].should == 'abc/def/ghi'
    end
  end

  describe 'expr' do
    it 'should get rule_expr as expr' do
      expr = @parser.expr.parse('abc')
      expr.should.has_key(:rule_expr)
      expr[:rule_expr][:rule_name].should == 'abc'
    end

    it 'should get number as expr' do
      expr = @parser.expr.parse('1')
      expr[:integer].should == "1"
    end

    it 'should get float as expr' do
      expr = @parser.expr.parse('0.1')
      expr[:float].should == "0.1"
    end

    it 'should get string as expr' do
      expr = @parser.expr.parse('"abc"')
      expr[:string].should == "abc"
    end

    it 'should parse parened expr' do
      expr = @parser.expr.parse('("abc")')
      expr[:string].should == "abc"
    end
  end

  describe 'feature expression' do
    it 'should parse a requisite feature expression' do
      expr = @parser.feature_expr.parse('+Linux')
      name = expr[:feature_expr][:requisite_feature_name]
      name[:feature_identifier].should == 'Linux'
    end

    it 'should parse a exclusive feature expression' do
      expr = @parser.feature_expr.parse('-Linux')
      name = expr[:feature_expr][:exclusive_feature_name]
      name[:feature_identifier].should == 'Linux'
    end

    it 'should parse a preferred feature expression' do
      expr = @parser.feature_expr.parse('?Linux')
      name = expr[:feature_expr][:preferred_feature_name]
      name[:feature_identifier].should == 'Linux'
    end

  end
end
