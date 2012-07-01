# -*- coding: utf-8 -*-

require_relative 'test-util'
require 'parslet/convenience'

describe 'Document' do
  before do
    @parser = Document::Parser.new
    @transform = Document::Transformer.new
  end
end
