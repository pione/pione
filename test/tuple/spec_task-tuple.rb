require_relative '../test-util'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::TaskTuple' do
  before do
    domain = "A"
    data = Tuple[:data].new(domain, "a.txt", Location["local:/home/keita/"], Time.now)

    @rule_path = "main_Main"
    @inputs = [data]
    @params = Parameters.new(Model::Variable.new("X") => Model::PioneInteger.new(1))
    @features = Feature.empty
    @domain = domain
    @call_stack = []

    args = [@rule_path, @inputs, @params, @features, @domain, @call_stack]
    @tuple = Tuple::TaskTuple.new(*args)
  end

  behaves_like "tuple"
end
