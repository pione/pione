require 'pione/test-helper'
require_relative 'tuple-behavior'

describe 'Pione::TupleSpace::TaskTuple' do
  before do
    domain = "A"
    data = TupleSpace::DataTuple.new(domain, "a.txt", Location["local:/home/keita/"], Time.now)

    @digest = "digest"
    @package_id = "Main"
    @rule_name = "Main"
    @inputs = [data]
    @params = Lang::ParameterSet.new(Lang::Variable.new("X") => Lang::IntegerSequence.of(1))
    @features = Lang::FeatureSequence.new
    @domain = domain
    @caller_id = "caller"

    args = [@digest, @package_id, @rule_name, @inputs, @params, @features, @domain, @caller_id]
    @tuple = TupleSpace::TaskTuple.new(*args)
  end

  behaves_like "tuple"
end
