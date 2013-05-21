require_relative '../test-util'
require_relative 'tuple-behavior'

describe 'Pione::Tuple::MessageTuple' do
  before do
    @tuple = Tuple::MessageTuple.new(type: "test", head: "test", color: :green, level: 0, contents: "test")
  end

  behaves_like "tuple"
end
