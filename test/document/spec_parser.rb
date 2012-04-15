# -*- coding: utf-8 -*-

require 'innocent-white/test-util'

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

  describe 'rule_name' do
    it 'should get a rule name' do
      tree = @parser.rule_name.parse('abc')
      tree[:rule_name].should == 'abc'
    end

    it 'should get a full rule path name' do
      tree = @parser.rule_name.parse('/abc/def/ghi')
      tree[:rule_name].should == '/abc/def/ghi'
    end
  end
end
