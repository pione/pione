require_relative '../test-util'

describe 'Pione::Tuple::TaskTuple' do
  before do
    domain = "A"
    data = Tuple[:data].new(domain, "a.txt", "local:/home/keita/", Time.now)

    @rule_path = "main_Main"
    @inputs = [data]
    @params = Parameters.new(Model::Variable.new("X") => Model::PioneInteger.new(1))
    @features = Feature.empty
    @domain = domain
    @call_stack = []

    args = [@rule_path, @inputs, @params, @features, @domain, @call_stack]
    @task = Tuple::TaskTuple.new(*args)
  end

  after do
    @task = nil
  end

  it 'should get the class from identifier' do
    Tuple[:task].should == Tuple::TaskTuple
  end

  it 'should get identifier' do
    @task.identifier.should == :task
  end

  it 'should get rule path' do
    @task.rule_path.should == @rule_path
  end

  it 'should set rule path' do
    rule_path = "B"
    @task.rule_path = rule_path
    @task.rule_path.should == rule_path
  end

  it 'should get inputs' do
    @task.inputs.should == @inputs
  end

  it 'should set inputs' do
    @task.inputs = []
    @task.inputs.should == []
  end

  it 'should get params' do
    @task.params.should == @params
  end

  it 'should set params' do
    params = Parameters.new(Model::Variable.new("Y") => Model::PioneInteger.new(2))
    @task.params = params
    @task.params.should == params
  end

  it 'should get features' do
    @task.features.should == @features
  end

  it 'should set features' do
    features = Model::Feature::RequestExpr.new("X")
    @task.features = features
    @task.features.should == features
  end

  it 'should get call-stack' do
    @task.call_stack.should == @call_stack
  end

  it 'should set call-stack' do
    call_stack = ["a", "b" , "c"]
    @task.call_stack = call_stack
    @task.call_stack.should == call_stack
  end

  it 'should get digest' do
    @task.digest.should == "main_Main([a.txt],{X:1})"
  end

  it 'should raise format error' do
    should.raise(Tuple::FormatError) do
      args = [true, @inputs, @params, @features, @domain, @call_stack]
      Tuple::TaskTuple.new(*args)
    end

    should.raise(Tuple::FormatError) do
      args = [@rule_path, true, @params, @features, @domain, @call_stack]
      Tuple::TaskTuple.new(*args)
    end

    should.raise(Tuple::FormatError) do
      args = [@rule_path, @inputs, true, @features, @domain, @call_stack]
      Tuple::TaskTuple.new(*args)
    end

    should.raise(Tuple::FormatError) do
      args = [@rule_path, @inputs, @params, true, @domain, @call_stack]
      Tuple::TaskTuple.new(*args)
    end

    should.raise(Tuple::FormatError) do
      args = [@rule_path, @inputs, @params, @features, true, @call_stack]
      Tuple::TaskTuple.new(*args)
    end

    should.raise(Tuple::FormatError) do
      args = [@rule_path, @inputs, @params, @features, @domain, true]
      Tuple::TaskTuple.new(*args)
    end
  end

  it 'should get any tuple' do
    any = Tuple::TaskTuple.any
    any.identifier.should == :task
    any.rule_path.should == nil
    any.inputs.should == nil
    any.params.should == nil
    any.features.should == nil
    any.domain.should == nil
    any.domain.should == nil
  end
end

