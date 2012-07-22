require_relative '../test-util'

describe 'Model::Parameters' do
  before do
    @params_a = Parameters.new({
        "a" => PioneString.new("A"),
        "b" => PioneString.new("B"),
        "c" => PioneString.new("C")
      })
  end

  it 'should be equal' do
    Parameters.new({"a" => "A", "b" => "B", "c" => "C"}).should ==
      Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
  end

  it 'should be not equal' do
    Parameters.new({"a" => "A", "b" => "B", "c" => "C"}).should.not ==
      Parameters.new({"a" => "X", "b" => "Y", "c" => "Z"})
  end

  it 'should get value' do
    params = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
    params.get("a").should == "A"
    params.get("b").should == "B"
    params.get("c").should == "C"
  end

  it 'should set a parameter' do
    params = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
    new_params = params.set("d", "D")
    new_params.get("a").should == "A"
    new_params.get("b").should == "B"
    new_params.get("c").should == "C"
    new_params.get("d").should == "D"
    params.get("d").should.nil
  end

  it 'should overwrite a parameter' do
    params = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
    new_params = params.set("a", "Z")
    new_params.get("a").should == "Z"
    new_params.get("b").should == "B"
    new_params.get("c").should == "C"
    params.get("a").should == "A"
  end

  it 'should delete a parameter' do
    params = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
    new_params = params.delete("a")
    new_params.get("a").should.nil
    new_params.get("b").should == "B"
    new_params.get("c").should == "C"
    params.get("a").should == "A"
  end

  it 'should clear parameters' do
    params = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
    new_params = params.clear
    new_params.should == Parameters.new({})
    params.get("a").should == "A"
  end

  it 'should be empty' do
    Parameters.new({}).should.be.empty
  end

  it 'should not be emtpy' do
    Parameters.new({"a" => "A", "b" => "B", "c" => "C"}).should.not.be.empty
  end

  describe 'pione method ==' do
    it 'should get true' do
      params_a = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
      params_b = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
      params_a.call_pione_method("==", params_b).should ==
        PioneBoolean.true
    end

    it 'should get false' do
      params_a = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
      params_b = Parameters.new({"a" => "X", "b" => "Y", "c" => "Z"})
      params_a.call_pione_method("==", params_b).should ==
        PioneBoolean.false
    end
  end

  describe 'pione method !=' do
    it 'should get true' do
      params_a = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
      params_b = Parameters.new({"a" => "X", "b" => "Y", "c" => "Z"})
      params_a.call_pione_method("!=", params_b).should ==
        PioneBoolean.true
    end

    it 'should get false' do
      params_a = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
      params_b = Parameters.new({"a" => "A", "b" => "B", "c" => "C"})
      params_a.call_pione_method("!=", params_b).should ==
        PioneBoolean.false
    end
  end

  describe 'pione method get' do
    it 'should get a value' do
      @params_a.call_pione_method("get", "a".to_pione).should ==
        "A".to_pione
    end
  end

  describe 'pione method set' do
    it 'should add a parameter' do
      new_params = @params_a.call_pione_method("set", "d".to_pione, "D".to_pione)
      new_params.get("d".to_pione).should == "D".to_pione
    end

    it 'should overwrite a parameter' do
      new_params = @params_a.call_pione_method("set", "a".to_pione, "X".to_pione)
      new_params.get("a".to_pione).should == "X".to_pione
    end
  end

  describe 'pione method clear' do
    it 'should clear' do
      new_params = @params_a.call_pione_method("clear")
      new_params.should.be.empty
    end
  end

  describe 'pione method empty?' do
    it 'should get true' do
      Parameters.new({}).call_pione_method("empty?").should ==
        PioneBoolean.true
    end
  end
end
