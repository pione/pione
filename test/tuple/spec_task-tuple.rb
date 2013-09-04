require_relative '../test-util'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::TaskTuple' do
  before do
    domain = "A"
    data = Tuple[:data].new(domain, "a.txt", Location["local:/home/keita/"], Time.now)

    @digest = "digest"
    @package_id = "Main"
    @rule_name = "Main"
    @inputs = [data]
    @params = ParameterSet.new(Model::Variable.new("X") => Model::IntegerSequence.of(1))
    @features = FeatureSequence.new
    @domain = domain
    @caller_id = "caller"

    args = [@digest, @package_id, @rule_name, @inputs, @params, @features, @domain, @caller_id]
    @tuple = Tuple::TaskTuple.new(*args)
  end

  behaves_like "tuple"
end
