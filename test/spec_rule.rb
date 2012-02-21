require 'innocent-white/rule'
#require 'innocent-white/agent/process-manager'
require 'innocent-white/agent/input-generator'

include InnocentWhite

Thread.abort_on_exception = true

describe 'Rule' do
  describe 'InputStringCompiler' do
    it 'should compile input string as regular expression' do
      input1 = Rule::InputStringCompiler.compile('test-1.a')
      input1.should.match 'test-1.a'
      input1.should.not.match 'test-1_a'
      input2 = Rule::InputStringCompiler.compile('test-\d.a')
      input2.should.not.match 'test-1.a'
    end

    it 'should compile "($*)" as /.*/' do
      input = Rule::InputStringCompiler.compile('test-($*).a')
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
      input.should.not.match 'test-1_a'
      input.should.match 'test-abc.a'
      input.match('test-abc.a')[1].should == 'abc'
    end

    it 'should handle "($*)" that written twice in the name 'do
      input = Rule::InputStringCompiler.compile('test-($*)-($*).a')
      input.should.match 'test-1-2.a'
      input.match('test-1-2.a')[1].should == '1'
      input.match('test-1-2.a')[2].should == '2'
      input.should.match 'test--.a'
      input.match('test--.a')[1].should == ''
      input.match('test--.a')[2].should == ''
    end

    it 'should compile "$(+)" as /.+/' do
      input = Rule::InputStringCompiler.compile('test-($+).a')
      input.should.not.match 'test-.a'
      input.should.match 'test-1.a'
      input.match('test-1.a')[1].should == '1'
      input.should.match 'test-2.a'
      input.match('test-2.a')[1].should == '2'
      input.should.match 'test-3.a'
      input.match('test-3.a')[1].should == '3'
      input.should.match 'test-A.a'
      input.match('test-A.a')[1].should == 'A'
      input.should.not.match 'test-1_a'
      input.should.match 'test-abc.a'
      input.match('test-abc.a')[1].should == 'abc'
    end

    it 'should handle "($+)" that written twice in the name 'do
      input = Rule::InputStringCompiler.compile('test-($+)-($+).a')
      input.should.match 'test-1-2.a'
      input.match('test-1-2.a')[1].should == '1'
      input.match('test-1-2.a')[2].should == '2'
      input.should.not.match 'test--.a'
    end
  end

  describe 'BaseRule' do
    before do
      @remote_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3))
      @ts_server = DRbObject.new(nil, @remote_server.uri)
      @generator = Agent[:input_generator].new(SimpleInputGeneratorMethod.new(@ts_server, 1..100, "a"))
    end

    it 'should find inputs' do

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

