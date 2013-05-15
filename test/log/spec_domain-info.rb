require_relative '../test-util'

class FakeHandler < RuleHandler::BasicHandler
  DOMAIN_LOCATION = Location[Temppath.create]

  def initialize
    @params = Parameters.new(Variable.new("X") => PioneString.new("a").to_seq)
    @original_params = @params
    @inputs = [Tuple::DataTuple.new(name: "A", domain: DOMAIN_LOCATION.to_s, location: DOMAIN_LOCATION + "A", time: Time.now)]
  end

  def domain_location
    DOMAIN_LOCATION
  end

  def execute
  end
end

describe 'Pione::Log::DomainInfo' do
  before do
    @info = Log::DomainInfo.new(FakeHandler.new)
  end

  it 'should get domain location' do
    @info.domain_location.should == FakeHandler::DOMAIN_LOCATION
  end

  it 'should create a domain information file' do
    @info.save
    (FakeHandler::DOMAIN_LOCATION + Log::DomainInfo::FILENAME).should.exist
  end

  it 'should get record' do
    @info.record.should.kind_of Hash
  end

  it 'should get sysname' do
    @info.system_name.should.not.nil
  end

  it 'should get nodename' do
    @info.system_nodename.should.not.nil
  end

  it 'should get machine' do
    @info.system_machine.should.not.nil
  end

  it 'should get version' do
    @info.system_version.should.not.nil
  end

  it 'should get relase' do
    @info.system_release.should.not.nil
  end
end
