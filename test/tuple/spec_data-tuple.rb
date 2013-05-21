require_relative '../test-util'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::TaskTuple' do
  before do
    @domain = "A"
    @name = Model::DataExpr.new("a.txt")
    @location = Location["local:/home/keita/"]
    @time = Time.now
    @tuple = Tuple::DataTuple.new(@domain, @name, @location, @time)
  end

  behaves_like "tuple"
end
