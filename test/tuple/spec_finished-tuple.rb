require_relative '../test-util'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::FinishedTuple' do
  before do
    @domain = "A"
    @status = :success

    name = Model::DataExpr.new("a.txt")
    location = Location["local:/home/keita/"]
    time = Time.now
    data = Tuple::DataTuple.new(@domain, name, location, time)

    @outputs = [data]
    @digest = "A"
    @tuple = Tuple::FinishedTuple.new(@domain, @status, @outputs, @digest)
  end

  behaves_like "tuple"
end
