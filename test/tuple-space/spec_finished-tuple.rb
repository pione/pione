require 'pione/test-helper'
require_relative 'tuple-behavior'

describe 'Pione::TupleSpace::FinishedTuple' do
  before do
    @domain = "A"
    @status = :success

    name = Lang::DataExprSequence.of("a.txt")
    location = Location["local:/home/keita/"]
    time = Time.now
    data = TupleSpace::DataTuple.new(@domain, name, location, time)

    @outputs = [data]
    @tuple = TupleSpace::FinishedTuple.new(@domain, Util::UUID.generate, @status, @outputs)
  end

  behaves_like "tuple"
end
