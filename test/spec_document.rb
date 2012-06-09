# -*- coding: utf-8 -*-

require 'pione/test-util'
require 'parslet/convenience'

describe 'Document' do
  before do
    @parser = Document::Parser.new
    @transform = Document::Transformer.new
  end

end
