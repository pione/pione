require 'pione/test-helper'
require_relative 'tuple-behavior'

describe 'Pione::TupleSpace::TouchTuple' do
  before do
    @domain = "A"
    @name = "a.txt"
    @time = Time.now
    @tuple = TupleSpace::TouchTuple.new(domain: @domain, name: @name, time: @time)
  end

  behaves_like "tuple"
end

