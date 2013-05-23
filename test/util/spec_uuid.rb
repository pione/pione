require_relative "../test-util"

describe "Pione::Util::UUID" do
  it "should genereate UUID as a string" do
    Util::UUID.generate.should.kind_of(String)
  end

  it "should generate UUID as an iteger" do
    Util::UUID.generate_int.should.kind_of(Integer)
  end
end
