require_relative 'test-util'

describe 'ID' do
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
      ID.task_id([], {"var" => "1.a"}.to_params),
      ID.task_id([], {"var" => "2.a"}.to_params),
      ID.task_id([DataExpr["1.a"]], {"var" => "1.a"}.to_params),
      ID.task_id([DataExpr["2.a"]], {"var" => "2.a"}.to_params)
    ]
    7.times do |i|
      7.times do |ii|
        id[i+1].should.not == id[ii+1] unless i == ii
      end
    end
  end
end
