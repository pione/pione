require 'pione/test-helper'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::FinishedTuple' do
  before do
    @domain = "A"
    @status = :success

    name = Lang::DataExprSequence.of("a.txt")
    location = Location["local:/home/keita/"]
    time = Time.now
    data = Tuple::DataTuple.new(@domain, name, location, time)

    @outputs = [data]
    @tuple = Tuple::FinishedTuple.new(@domain, @status, @outputs)
  end

  behaves_like "tuple"
end
