require 'innocent-white/test-util'
require 'innocent-white/data-name-exp'
require 'innocent-white/rule'
require 'innocent-white/document'
require 'innocent-white/agent/input-generator'

describe 'Rule' do
  describe 'ActionRule' do
    before do
      @ts_server = create_remote_tuple_space_server
      @gen1 = Agent[:input_generator].new_by_simple(@ts_server, "*.a", 1..10, 11..20)
      @gen2 = Agent[:input_generator].new_by_simple(@ts_server, "*.b", 1..10, 11..20)
      @rule = Document.new do
        action('test') do
          inputs  '*.a', '{$INPUT[1].MATCH[1]}.b'
          outputs '{$INPUT[1].MATCH[1]}.c'
          content 'expr {$INPUT[1].VALUE} + {$INPUT[2].VALUE}'
        end
      end['test']
    end

    it 'should get inputs' do
      input_a = DataNameExp.new('*.a')
      input_b = DataNameExp.new('{$INPUT[1].MATCH[1]}.b')
      @rule.inputs.should == [input_a, input_b]
    end

    it 'should get outputs' do
      output_c = DataNameExp.new('{$INPUT[1].MATCH[1]}.c')
      @rule.outputs.should == [output_c]
    end

    it 'should find inputs' do
      @gen1.wait_till(:terminated)
      @gen2.wait_till(:terminated)
      check_exceptions
      inputs = @rule.find_inputs(@ts_server, "/input")
      inputs.size.should == 10
      10.times do |i|
        a = @ts_server.read(Tuple[:data].new(name: "#{i+1}.a"))
        b = @ts_server.read(Tuple[:data].new(name: "#{i+1}.b"))
        inputs.should.include [a, b]
      end
    end
  end

  describe 'ActionHandler' do
    before do
      @ts_server = create_remote_tuple_space_server
      @gen1 = Agent[:input_generator].new_by_simple(@ts_server, "test-*.a", 1..10, 1..10)
      @gen2 = Agent[:input_generator].new_by_simple(@ts_server, "test-*.b", 1..10, 11..20)
      @rule = Document.new do
        action('test') do
          inputs  '*.a', '{$INPUT[1].MATCH[1]}.b'
          outputs '{$INPUT[1].MATCH[1]}.c'
          content <<-__SH__
            VAL1=`cat {$INPUT[1]}`;
            VAL2=`cat {$INPUT[2]}`;
            expr $VAL1 + $VAL2
          __SH__
        end
      end['test']
      @gen1.wait_till(:terminated)
      @gen2.wait_till(:terminated)
    end

    it 'should make action handler from action rule' do
      inputs = @rule.find_inputs(@ts_server, '/input').first
      handler = @rule.make_handler(inputs, [])
      handler.should.kind_of Rule::ActionHandler
    end

    it 'should make working directory with no process informations' do
      inputs = @rule.find_inputs(@ts_server, '/input').first
      handler = @rule.make_handler(inputs, [])
      path = handler.working_directory
      Dir.exist?(path).should.be.true
    end

    it 'should make working directory with process informations' do
      inputs = @rule.find_inputs(@ts_server, '/input').first
      process_name = "test-process-123"
      process_id = "xyz"
      opts = {:process_name => process_name, :process_id => process_id}
      handler = @rule.make_handler(inputs, [], opts)
      path = handler.working_directory
      Dir.exist?(path).should.be.true
      path.should.include? "#{process_name}_#{process_id}"
    end

    it 'should execute an action' do
      inputs = @rule.find_inputs(@ts_server, '/input').first
      handler = @rule.make_handler(inputs, [])
      result = handler.execute
      output = result.ouputs.first
      output.name.should == 'test-1.c'
      Resource[URI(output.uri)].read.should == "12"
    end
  end
end
