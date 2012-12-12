require_relative '../test-util'

describe 'Pione::Tuple::FinishedTuple' do
  before do
    @domain = "A"
    @status = :success

    name = Model::DataExpr.new("a.txt")
    uri = "local:/home/keita/"
    time = Time.now
    data = Tuple::DataTuple.new(@domain, name, uri, time)

    @outputs = [data]
    @digest = "A"
    @data = Tuple::FinishedTuple.new(@domain, @status, @outputs, @digest)
  end

  after do
    @data = nil
  end

  it 'should get domain' do
    @data.domain.should == @domain
  end

  it 'should set domain' do
    domain = "B"
    @data.domain = domain
    @data.domain.should == domain
  end

  it 'should get status' do
    @data.status.should == @status
  end

  it 'should set status' do
    status = :failed
    @data.status = status
    @data.status.should == status
  end

  it 'should get outputs' do
    @data.outputs.should == @outputs
  end

  it 'should set outputs' do
    outputs = []
    @data.outputs = outputs
    @data.outputs.should == outputs
  end

  it 'should get digest' do
    @data.digest.should == @digest
  end

  it 'should set digest' do
    digest = "B"
    @data.digest = digest
    @data.digest.should == digest
  end
end
