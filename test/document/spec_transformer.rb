# -*- coding: utf-8 -*-

require 'innocent-white/test-util'

describe 'Document::Parser' do
  before do
    @parser = Document::Parser.new
    @transformer = Document::Transformer.new
  end

  describe 'data_name' do
    it 'should include a single quote' do
      text = "'test\\'.a'"
      data = @transformer.apply(@parser.data_name.parse(text))
      data.should == "test\'.a"
    end
  end
end
