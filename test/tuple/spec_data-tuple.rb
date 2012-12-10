require_relative '../test-util'

describe 'Pione::Tuple::TaskTuple' do
  before do
    @domain = "A"
    @name = Model::DataExpr.new("a.txt")
    @uri = "local:/home/keita/"
    @time = Time.now
    @data = Tuple::DataTuple.new(@domain, @name, @uri, @time)
  end

  after do
    @data = nil
  end

  it 'should get identifier' do
    @data.identifier.should == :data
  end

  it 'should get the domain' do
    @data.domain.should == @domain
  end

  it 'should set the domain' do
    domain = "B"
    @data.domain = domain
    @data.domain.should == domain
  end

  it 'should get name' do
    @data.name.should == @name
  end

  it 'should set name' do
    name = "b.txt"
    @data.name = name
    @data.name.should == name
  end

  it 'should get URI' do
    @data.uri.should == @uri
  end

  it 'should set URI' do
    uri = "local:./output"
    @data.uri = uri
    @data.uri.should == uri
  end

  it 'should get time' do
    @data.time.should == @time
  end

  it 'should set time' do
    time = Time.now
    @data.time = time
    @data.time.should == time
  end

  it 'should raise FormatError' do
    should.raise(Tuple::FormatError) do
      Tuple::DataTuple.new(true, @name, @uri, @time)
    end

    should.raise(Tuple::FormatError) do
      Tuple::DataTuple.new(@domain, true, @uri, @time)
    end

    should.raise(Tuple::FormatError) do
      Tuple::DataTuple.new(@domain, @name, true, @time)
    end

    should.raise(Tuple::FormatError) do
      Tuple::DataTuple.new(@domain, @name, @uri, true)
    end
  end

  it 'should get any tuple' do
    any = Tuple::DataTuple.any
    any.domain.should == nil
    any.name.should == nil
    any.uri.should == nil
    any.time.should == nil
  end
end
