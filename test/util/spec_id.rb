require_relative "../test-util"

location = Location[File.dirname(__FILE__)] + "spec_id.pione"

describe "Pione::Util::TaskID" do
  before do
    @t1 = Tuple[:data].new(domain: "test", name: "1.a", location: Location[Temppath.create], time: Time.now)
    @t2 = Tuple[:data].new(domain: "test", name: "2.a", location: Location[Temppath.create], time: Time.now)
    @p1 = Parameters.new({Variable.new("X") => PioneString.new("A").to_seq})
    @p2 = Parameters.new({Variable.new("X") => PioneString.new("B").to_seq})
  end

  it "should generate task id" do
    Util::TaskID.generate([], Parameters.empty).size.should > 0
  end

  it "should genereate different ids from different inputs" do
    Util::TaskID.generate([@t1], Parameters.empty).should !=
      Util::TaskID.generate([@t2], Parameters.empty)
  end

  it "should generate differnt ids from different parameters" do
    Util::TaskID.generate([], @p1).should !=
      Util::TaskID.generate([], @p2)
  end
end

describe "Pione::Util::DomainID" do
  before do
    document1 = Component::Document.load(location, "ID1")
    document2 = Component::Document.load(location, "ID2")
    @r1 = document1.find("R1")
    @r2 = document1.find("R2")
    @r3 = document2.find("R1")
    @r4 = document2.find("R2")
    @t1 = Tuple[:data].new(domain: "test", name: "1.a", location: Location[Temppath.create], time: Time.now)
    @t2 = Tuple[:data].new(domain: "test", name: "2.a", location: Location[Temppath.create], time: Time.now)
    @p1 = Parameters.new({Variable.new("X") => PioneString.new("A").to_seq})
    @p2 = Parameters.new({Variable.new("X") => PioneString.new("B").to_seq})
  end

  it "should generate domain id" do
    Util::DomainID.generate(@r1, [], Parameters.empty).size.should > 0
    Util::DomainID.generate(@r2, [], Parameters.empty).size.should > 0
    Util::DomainID.generate(@r3, [], Parameters.empty).size.should > 0
    Util::DomainID.generate(@r4, [], Parameters.empty).size.should > 0
  end

  it "should generate same id from same rule, inputs, and parameters" do
    Util::DomainID.generate(@r1, [], Parameters.empty).should ==
      Util::DomainID.generate(@r1, [], Parameters.empty)
  end

  it "should generate differnet ids from different packages" do
    Util::DomainID.generate(@r1, [], Parameters.empty).should !=
      Util::DomainID.generate(@r3, [], Parameters.empty)
    Util::DomainID.generate(@r2, [], Parameters.empty).should !=
      Util::DomainID.generate(@r4, [], Parameters.empty)
  end

  it "should generate differnet ids from different rules" do
    Util::DomainID.generate(@r1, [], Parameters.empty).should !=
      Util::DomainID.generate(@r2, [], Parameters.empty)
    Util::DomainID.generate(@r3, [], Parameters.empty).should !=
      Util::DomainID.generate(@r4, [], Parameters.empty)
  end

  it "should generate different ids from different inputs" do
    Util::DomainID.generate(@r1, [@t1], Parameters.empty).should !=
      Util::DomainID.generate(@r1, [@t2], Parameters.empty)
  end

  it "should generate different ids from different parameters" do
    Util::DomainID.generate(@r1, [], @p1).should !=
      Util::DomainID.generate(@r1, [], @p2)
  end
end
