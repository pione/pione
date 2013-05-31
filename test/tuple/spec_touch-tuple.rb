require_relative '../test-util'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::TouchTuple' do
  before do
    @domain = "A"
    @name = "a.txt"
    @time = Time.now
    @tuple = Tuple::TouchTuple.new(domain: @domain, name: @name, time: @time)
  end

  behaves_like "tuple"
end

