require_relative 'test-util'

describe 'ID' do
  before do
    @params_1 = Parameters.new(Variable.new("var") => PioneString.new("1.a"))
    @params_2 = Parameters.new(Variable.new("var") => PioneString.new("2.a"))
  end

  it 'should get task id' do
    ID.task_id([], Parameters.empty).size.should == 32
  end

  it 'should get same id from same task' do
    id = ID.task_id([DataExpr["1.a"]], Parameters.empty)
    id.should == ID.task_id([DataExpr["1.a"]], Parameters.empty)
  end

  it 'should get different id from different task' do
    id = [
      ID.task_id([], Parameters.empty),
      ID.task_id([DataExpr["1.a"]], Parameters.empty),
      ID.task_id([DataExpr["2.a"]], Parameters.empty),
      ID.task_id([], @params_1),
      ID.task_id([], @params_2),
      ID.task_id([DataExpr["1.a"]], @params_1),
      ID.task_id([DataExpr["2.a"]], @params_2)
    ]
    7.times do |i|
      7.times do |ii|
        id[i+1].should.not == id[ii+1] unless i == ii
      end
    end
  end
end
