require 'pione/test-helper'
require_relative 'tuple-behavior'

describe 'Pione::TupleSpace::MessageTuple' do
  before do
    @tuple = TupleSpace::MessageTuple.new(type: "test", head: "test", color: :green, level: 0, contents: "test")
  end

  behaves_like "tuple"
end
