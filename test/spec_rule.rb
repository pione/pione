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
      inputs = @rule.find_input_combinations(@ts_server, "/input")
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
            expr $VAL1 + $VAL2 > {$OUTPUT[1]}
          __SH__
        end
      end['test']
      @tmpdir = Dir.mktmpdir
      @base_uri = "local:#{@tmpdir}/"
      @gen1.wait_till(:terminated)
      @gen2.wait_till(:terminated)
    end

    it 'should make action handler from action rule' do
      input_data = @rule.find_input_combinations(@ts_server, '/input').first
      handler = @rule.make_handler(@base_uri, input_data, [])
      handler.should.kind_of Rule::ActionHandler
    end

    it 'should make working directory with no process informations' do
      input_data = @rule.find_input_combinations(@ts_server, '/input').first
      handler = @rule.make_handler(@base_uri, input_data, [])
      path = handler.working_directory
      Dir.exist?(path).should.be.true
    end

    it 'should make working directory with process informations' do
      input_data = @rule.find_input_combinations(@ts_server, '/input').first
      process_name = "test-process-123"
      process_id = "xyz"
      opts = {:process_name => process_name, :process_id => process_id}
      handler = @rule.make_handler(@base_uri, input_data, [], opts)
      path = handler.working_directory
      Dir.exist?(path).should.be.true
      path.should.include? "#{process_name}_#{process_id}"
    end

    it 'should execute an action' do
      inputs = @rule.find_input_combinations(@ts_server, '/input').first
      handler = @rule.make_handler(@base_uri, inputs, [])
      result = handler.execute(@ts_server)
      output_data = result.first
      output_data.name.should == 'test-1.c'
      Resource[output_data.uri].read.chomp.should == "12"
      should.not.raise do
        tuple = @ts_server.read(output_data)
        tuple.name.should == output_data.name
        tuple.uri.should == output_data.uri
      end
    end
  end
end
