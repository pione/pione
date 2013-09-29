require 'pione/test-helper'

location = Location[File.dirname(__FILE__)] + "spec_id.pione"

describe "Pione::Util::TaskID" do
  before do
    @t1 = TupleSpace::DataTuple.new(domain: "test", name: "1.a", location: Location[Temppath.create], time: Time.now)
    @t2 = TupleSpace::DataTuple.new(domain: "test", name: "2.a", location: Location[Temppath.create], time: Time.now)
    @p1 = Lang::ParameterSet.new(table: {"X" => Lang::StringSequence.of("A")})
    @p2 = Lang::ParameterSet.new(table: {"X" => Lang::StringSequence.of("B")})
  end

  it "should generate task id" do
    Util::TaskID.generate([], Lang::ParameterSet.new).size.should > 0
  end

  it "should genereate different ids from different inputs" do
    Util::TaskID.generate([@t1], Lang::ParameterSet.new).should !=
      Util::TaskID.generate([@t2], Lang::ParameterSet.new)
  end

  it "should generate differnt ids from different parameters" do
    Util::TaskID.generate([], @p1).should !=
      Util::TaskID.generate([], @p2)
  end
end

describe "Pione::Util::DomainID" do
  before do
    @env = TestHelper::Lang.env
    @pid1 = Util::PackageID.generate(@env, "A")
    @pid2 = Util::PackageID.generate(@env, "B")
    @name1 = "R1"
    @name2 = "R2"
    @t1 = TupleSpace::DataTuple.new(domain: "test", name: "1.a", location: Location[Temppath.create], time: Time.now)
    @t2 = TupleSpace::DataTuple.new(domain: "test", name: "2.a", location: Location[Temppath.create], time: Time.now)
    @p0 = Lang::ParameterSet.new
    @p1 = Lang::ParameterSet.new(table: {"X" => Lang::StringSequence.of("A")})
    @p2 = Lang::ParameterSet.new(table: {"X" => Lang::StringSequence.of("B")})
  end

  it "should generate domain id" do
    Util::DomainID.generate(@pid1, @name1, [], @p0).size.should > 0
    Util::DomainID.generate(@pid1, @name2, [], @p0).size.should > 0
    Util::DomainID.generate(@pid2, @name1, [], @p0).size.should > 0
    Util::DomainID.generate(@pid2, @name2, [], @p0).size.should > 0
  end

  it "should generate same id from same rule, inputs, and parameters" do
    Util::DomainID.generate(@pid1, @name1, [], @p0).should ==
      Util::DomainID.generate(@pid1, @name1, [], @p0)
  end

  it "should generate differnet ids from different packages" do
    Util::DomainID.generate(@pid1, @name1, [], @p0).should !=
      Util::DomainID.generate(@pid2, @name1, [], @p0)
    Util::DomainID.generate(@pid1, @name2, [], @p0).should !=
      Util::DomainID.generate(@pid2, @name2, [], @p0)
  end

  it "should generate differnet ids from different rules" do
    Util::DomainID.generate(@pid1, @name1, [], @p0).should !=
      Util::DomainID.generate(@pid1, @name2, [], @p0)
    Util::DomainID.generate(@pid2, @name1, [], @p0).should !=
      Util::DomainID.generate(@pid2, @name2, [], @p0)
  end

  it "should generate different ids from different inputs" do
    Util::DomainID.generate(@pid1, @name1, [@t1], @p0).should !=
      Util::DomainID.generate(@pid1, @name1, [@t2], @p0)
  end

  it "should generate different ids from different parameters" do
    Util::DomainID.generate(@pid1, @name1, [], @p1).should !=
      Util::DomainID.generate(@pid1, @name1, [], @p2)
  end
end

describe "Pione::Util::PackageID" do
  it "should generate package id based on package name" do
    env = TestHelper::Lang.env
    id = Util::PackageID.generate(env, "Test")
    id.should != "Test"
    id.should.include "Test"
  end

  it "should generate different ids from same package name" do
    env = TestHelper::Lang.env
    id1 = Util::PackageID.generate(env, "Test")
    id2 = Util::PackageID.generate(env, "Test")
    id1.should != id2
  end
end

