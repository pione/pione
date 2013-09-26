require 'pione/test-helper'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::DataTuple' do
  before do
    @domain = "A"
    @name = Lang::DataExprSequence.of("a.txt")
    @location = Location["local:/home/keita/"]
    @time = Time.now
    @tuple = Tuple::DataTuple.new(@domain, @name, @location, @time)
  end

  behaves_like "tuple"
end
