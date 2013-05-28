require_relative "../test-util"

describe "Pione::System::DomainInfo" do
  before do
    @vtable = Model::VariableTable.new
    @vtable.set(Variable.new("A"), Model::PioneInteger.new(1).to_seq)
    @vtable.set(Variable.new("B"), Model::PioneFloat.new(1.23).to_seq)
    @vtable.set(Variable.new("C"), Model::PioneString.new("A").to_seq)
    @vtable.set(Variable.new("D"), Model::PioneBoolean.new(true).to_seq)
    @location = Location[Temppath.create].tap do |location|
      System::DomainInfo.new(@vtable).write(location)
    end
  end

  it "should write a domain info file" do
    location = Location[Temppath.create]
    System::DomainInfo.new(@vtable).write(location)
    location.should.exist
  end

  it "should read a domain info file" do
    System::DomainInfo.read(@location).variable_table.should == @vtable
  end
end

