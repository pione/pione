require_relative '../test-util'

describe 'Pione::Transformer::DocumentTransformer' do
  transformer_spec("param_block", :param_block) do
    test(<<-STRING) do |res|
      Param
        $X := 1
        $Y := 2
        $Z := 3
      End
    STRING
      assignments = res.value
      assignments.size.should == 3
      assignments.each do |assignment|
        assignment.should.kind_of Model::Assignment
        assignment.variable.param_type.should == :basic
      end
      assignments[0].variable.should == Variable.new("X")
      assignments[0].expr.should == IntegerSequence.new([PioneInteger.new(1)])
      assignments[1].variable.should == Variable.new("Y")
      assignments[1].expr.should == IntegerSequence.new([PioneInteger.new(2)])
      assignments[2].variable.should == Variable.new("Z")
      assignments[2].expr.should == IntegerSequence.new([PioneInteger.new(3)])
    end

    test(<<-STRING) do |res|
      Basic Param
        $X := 1
        $Y := 2
        $Z := 3
      End
    STRING
      res.value.should.all do |assignment|
        assignment.variable.param_type == :basic
      end
    end

    test(<<-STRING) do |res|
      Advanced Param
        $X := 1
        $Y := 2
        $Z := 3
      End
    STRING
      res.value.should.all do |assignment|
        assignment.variable.param_type == :advanced
      end
    end
  end
end
