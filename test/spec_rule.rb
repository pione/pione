require 'innocent-white/rule'
require 'innocent-white/agent/input-generator'

include InnocentWhite

Thread.abort_on_exception = true

describe 'Rule' do
  describe 'DataNameExp' do
    it 'should compile string as regular expression' do
      input1 = Rule::DataNameExp.regexp('test-1.a')
      input1.should.match 'test-1.a'
      input1.should.not.match 'test-1_a'
      input2 = Rule::DataNameExp.regexp('test-\d.a')
      input2.should.not.match 'test-1.a'
    end

    it 'should handle wildcard "*" as /(.*)/ (Case 1)' do
      input = Rule::DataNameExp.regexp('test-*.a')
      input.should.match 'test-.a'
      input.match('test-.a')[1].should == ''
      input.should.match 'test-1.a'
      input.match('test-1.a')[1].should == '1'
      input.should.match 'test-2.a'
      input.match('test-2.a')[1].should == '2'
      input.should.match 'test-3.a'
      input.match('test-3.a')[1].should == '3'
      input.should.match 'test-A.a'
      input.match('test-A.a')[1].should == 'A'
      input.should.match 'test-abc.a'
      input.match('test-abc.a')[1].should == 'abc'
      input.should.not.match 'test-1_a'
      input.should.not.match '-1.a'
      input.should.not.match 'test-1.ab'
      input.should.not.match 'ttest-1.a'
    end

    it 'should handle wildcard "*" as /(.*)/ (Case 2)'do
      input = Rule::DataNameExp.regexp('test-*-*.a')
      input.should.match 'test-1-2.a'
      input.match('test-1-2.a')[1].should == '1'
      input.match('test-1-2.a')[2].should == '2'
      input.should.match 'test-abc-xyz.a'
      input.match('test-abc-xyz.a')[1].should == 'abc'
      input.match('test-abc-xyz.a')[2].should == 'xyz'
      input.should.match 'test--.a'
      input.match('test--.a')[1].should == ''
      input.match('test--.a')[2].should == ''
      input.should.not.match('test-1.a')
      input.should.not.match('test-1-2.b')
      input.should.not.match('test-1-2')
      input.should.not.match('-1-2.a')
      input.should.not.match 'test-1-2.ab'
      input.should.not.match 'ttest-1-2.a'
    end

    it 'should handle "?" as /(.)/ (Case 1)' do
      input = Rule::DataNameExp.regexp('test-?.a')
      input.should.match 'test-1.a'
      input.match('test-1.a')[1].should == '1'
      input.should.match 'test-2.a'
      input.match('test-2.a')[1].should == '2'
      input.should.match 'test-3.a'
      input.match('test-3.a')[1].should == '3'
      input.should.match 'test-A.a'
      input.match('test-A.a')[1].should == 'A'
      input.should.not.match 'test-abc.a'
      input.should.not.match 'test-.a'
      input.should.not.match 'test-1_a'
      input.should.not.match 'test-1.ab'
      input.should.not.match 'ttest-1.a'
    end

    it 'should handle "?" as /(.)/ (Case 2)' do
      input = Rule::DataNameExp.regexp('test-?-?.a')
      input.should.match 'test-1-2.a'
      input.match('test-1-2.a')[1].should == '1'
      input.match('test-1-2.a')[2].should == '2'
      input.should.not.match 'test--.a'
      input.should.not.match 'test-abc-a.a'
      input.should.not.match 'test-a-abc.a'
      input.should.not.match 'test-1-2.ab'
      input.should.not.match 'ttest-1-2.a'
    end

    it 'should expand variables' do
      input1 = Rule::DataNameExp.regexp('{$VAR}.a', {'VAR' => '1'})
      input1.should.match '1.a'
      input1.should.not.match '1.b'
      input2 = Rule::DataNameExp.regexp('{$VAR}.a', {'VAR' => '*'})
      input2.should.match '1.a'
      input2.should.match '2.a'
      input2.should.match 'abc.a'
      input2.should.not.match '1.b'
    end
  end

  describe 'ActionRule' do
    before do
      @remote_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3))
      @ts_server = DRbObject.new(nil, @remote_server.uri)
      @gen1 = Agent[:input_generator].new_by_simple(@ts_server, "*.a", 1..10, 11..20)
      @gen2 = Agent[:input_generator].new_by_simple(@ts_server, "*.b", 1..10, 11..20)
      inputs = ['*.a', '{$INPUT[1].MATCH[1]}.b'].map{|name| Rule::DataNameExp.new(name)}
      outputs = ['{$INPUT[1].MATCH[1]}.c'].map{|name| Rule::DataNameExp.new(name)}
      @rule = Rule::ActionRule.new(inputs, outputs, [], "expr {$INPUT[1].VALUE} + {$INPUT[2].VALUE}")
    end

    it 'should find inputs and outputs' do
      @gen1.wait_till(:terminated)
      @gen2.wait_till(:terminated)
      inputs = @rule.find_inputs(@ts_server, "/")
      inputs.size.should == 10
      10.times do |i|
        a = @ts_server.read(Tuple[:data].new(name: "#{i+1}.a"))
        b = @ts_server.read(Tuple[:data].new(name: "#{i+1}.b"))
        inputs.should.include [a, b]
      end
    end
  end

  # before do
  #   @ts_server = TupleSpaceServer.new(task_worker_resource: 3)
  #   @generator = Agent[:input_generator].new(@ts_server, 1..10, "a")
  #   document = {"/main" => ProcessHandler::Action.define(inputs: [/(.*).a/],
  #                                                       outputs: ["{$1}.a"],
  #                                                       content: "echo 'abc' > {$OUTPUT}")}
  #   @manager = Agent[:process_manager].new(@ts_server, document)
  # end
  
  # it "should make tasks" do
  #   sleep 0.2
  #   @ts_server.count_tuple(Tuple[:task].any).should == 10
  # end

end

