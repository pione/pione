shared "tuple" do
  it 'should get the identifier' do
    Tuple.identifiers.should.include(@tuple.identifier)
  end

  it 'should get records' do
    @tuple.class.format.each do |key|
      key, _ = key
      should.not.raise do
        @tuple.__send__(key)
      end
    end
  end
end
