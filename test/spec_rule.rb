require 'innocent-white/test-util'
require 'innocent-white/rule'
require 'innocent-white/agent/input-generator'
require 'innocent-white/agent/task-worker'
require 'innocent-white/agent/rule-provider'

describe 'Rule' do
  describe 'ActionRule and FlowRule' do
    before do
      @ts_server = create_remote_tuple_space_server
      @doc = Document.new do
        flow('flow') do
          inputs '*.a', '{$INPUT[1].MATCH[1]}.b'
          outputs '{$INPUT[1].MATCH[1]}.c'
          content [call('action')]
        end

        action('action') do
          inputs  '*.a', '{$INPUT[1].MATCH[1]}.b'
          outputs '{$INPUT[1].MATCH[1]}.c'
          content 'expr {$INPUT[1].VALUE} + {$INPUT[2].VALUE}'
        end
      end
      @rules = @doc.rules.values
    end

    it 'should get inputs' do
      @rules.each do |rule|
        input_a = DataExp.new('*.a')
        input_b = DataExp.new('{$INPUT[1].MATCH[1]}.b')
        rule.inputs.should == [input_a, input_b]
      end
    end

    it 'should get outputs' do
      @rules.each do |rule|
        output_c = DataExp.new('{$INPUT[1].MATCH[1]}.c')
        rule.outputs.should == [output_c]
      end
    end

    it 'should find inputs' do
      # start input generators
      gen1 = Agent[:input_generator].start_by_simple(@ts_server, "*.a", 1..10, 1..10)
      gen2 = Agent[:input_generator].start_by_simple(@ts_server, "*.b", 1..10, 1..10)
      gen1.wait_till(:terminated)
      gen2.wait_till(:terminated)
      check_exceptions

      # find combinations
      @rules.each do |rule|
        inputs = rule.find_input_combinations(@ts_server, "/input")
        inputs.size.should == 10
        10.times do |i|
          a = @ts_server.read(Tuple[:data].new(name: "#{i+1}.a"))
          b = @ts_server.read(Tuple[:data].new(name: "#{i+1}.b"))
          inputs.should.include [a, b]
        end
      end
    end

    it 'should make an action handler' do
      # start input generators
      gen1 = Agent[:input_generator].start_by_simple(@ts_server, "*.a", 1..10, 1..10)
      gen2 = Agent[:input_generator].start_by_simple(@ts_server, "*.b", 1..10, 1..10)
      gen1.wait_till(:terminated)
      gen2.wait_till(:terminated)
      check_exceptions

      # make a handler
      @rules.each do |rule|
        input_comb = rule.find_input_combinations(@ts_server, "/input")
        input_comb.each do |inputs|
          handler = rule.make_handler(tuple_space_server, inputs, [])
          if rule.kind_of?(Rule::ActionRule)
            handler.should.be.kind_of Rule::ActionHandler
          else
            handler.should.be.kind_of Rule::FlowHandler
          end
        end
      end
    end
  end

  describe 'ActionHandler' do
    before do
      @ts_server = create_remote_tuple_space_server
      @doc = Document.new do
        action('rule_sh_1') do
          inputs  '*.a', '{$INPUT[1].MATCH[1]}.b'
          outputs '{$INPUT[1].MATCH[1]}.c'
          content <<-__CODE__
            VAL1=`cat {$INPUT[1]}`;
            VAL2=`cat {$INPUT[2]}`;
            expr $VAL1 + $VAL2 > {$OUTPUT[1]}
          __CODE__
        end

        action('rule_sh_2') do
          inputs  '*.a', '{$INPUT[1].*}.b'
          outputs '{$INPUT[1].*}.c'.stdout
          content <<-__CODE__
            VAL1=`cat {$INPUT[1]}`;
            VAL2=`cat {$INPUT[2]}`;
            expr $VAL1 + $VAL2
          __CODE__
        end

        action('rule_ruby') do
          inputs  '*.a', '{$INPUT[1].*}.b'
          outputs '{$INPUT[1].*}.c'.stdout
          content ruby(<<-'__CODE__')
            val1 = File.read('{$INPUT[1]}').to_i
            val2 = File.read('{$INPUT[2]}').to_i
            puts val1 + val2
          __CODE__
        end
      end
      @rule = @doc['rule_sh_1']
      @doc.rules.keys.each {|key| eval "@#{key} = @doc['#{key}']"}
      @base_uri = read(Tuple[:base_uri].any).uri

      # setup generators
      @gen1 = Agent[:input_generator].start_by_simple(@ts_server, "test-*.a", 1..10, 1..10)
      @gen2 = Agent[:input_generator].start_by_simple(@ts_server, "test-*.b", 1..10, 11..20)
      @gen1.wait_till(:terminated)
      @gen2.wait_till(:terminated)
    end

    it 'should make working directory with no process informations' do
      inputs = @rule.find_input_combinations(@ts_server, '/input').first
      handler = Rule::ActionHandler.new(tuple_space_server, @rule, inputs, [])
      path = handler.working_directory
      Dir.exist?(path).should.be.true
    end

    it 'should make working directory with process informations' do
      inputs = @rule.find_input_combinations(@ts_server, '/input').first
      process_name = "test-process-123"
      process_id = "xyz"
      opts = {:process_name => process_name, :process_id => process_id}
      handler = Rule::ActionHandler.new(tuple_space_server, @rule, inputs, [], opts)
      path = handler.working_directory
      Dir.exist?(path).should.be.true
      path.should.include? "#{process_name}_#{process_id}"
    end

    it 'should execute an action' do
      input_comb = @rule.find_input_combinations(@ts_server, '/input')
      10.times do |i|
        handler = Rule::ActionHandler.new(tuple_space_server, @rule, input_comb[i], [])

        # execute and get result
        result = handler.execute
        output_data = result.first
        output_data.name.should == "test-#{i+1}.c"

        # validate output, resouce, and tuple space
        Resource[output_data.uri].read.chomp.should == ((i+1)*2 + 10).to_s
        tuple = @ts_server.read(output_data)
        tuple.name.should == output_data.name
        tuple.uri.should == output_data.uri
      end
    end

    it 'should handle output in stdout' do
      input_comb = @rule_sh_2.find_input_combinations(@ts_server, '/input')
      10.times do |i|
        handler = Rule::ActionHandler.new(tuple_space_server, @rule, input_comb[i], [])

        # execute and get result
        result = handler.execute
        output_data = result.first
        output_data.name.should == "test-#{i+1}.c"

        # validate output, resouce, and tuple space
        Resource[output_data.uri].read.chomp.should == ((i+1)*2 + 10).to_s
      end
    end

    it 'should execute ruby script' do
      input_comb = @rule_ruby.find_input_combinations(@ts_server, '/input')
      10.times do |i|
        handler = Rule::ActionHandler.new(tuple_space_server, @rule, input_comb[i], [])

        # execute and get result
        result = handler.execute
        output_data = result.first
        output_data.name.should == "test-#{i+1}.c"

        # validate output, resouce, and tuple space
        Resource[output_data.uri].read.chomp.should == ((i+1)*2 + 10).to_s
      end
    end
  end
end

describe 'Rule::FlowHandler' do
  before do
    @ts_server = create_remote_tuple_space_server
    @doc = Document.new do
      flow('flow1') do
        inputs  all('*.a'), all('*.b')
        outputs all('*.c')
        content [ call('action_a'),
                  call('action_b'),
                  call('action_c') ]
      end

      action('action_a') do
        inputs  '*.a', '{$INPUT[1].MATCH[1]}.b'
        outputs '{$INPUT[1].MATCH[1]}.x'
        content <<-__CODE__
            VAL1=`cat {$INPUT[1]}`;
            VAL2=`cat {$INPUT[2]}`;
            expr $VAL1 + $VAL2 > {$OUTPUT[1]}
          __CODE__
      end

      action('action_b') do
        inputs  '*.x'
        outputs '{$INPUT[1].MATCH[1]}.y'
        content <<-__CODE__
            VAL1=`cat {$INPUT[1]}`;
            expr $VAL1 \\* 3 > {$OUTPUT[1]}
          __CODE__
      end

      action('action_c') do
        inputs  '*.y'
        outputs '{$INPUT[1].MATCH[1]}.c'
        content <<-__CODE__
            VAL1=`cat {$INPUT[1]}`;
            expr $VAL1 - 1  > {$OUTPUT[1]}
          __CODE__
      end
    end
    @rule = @doc['flow1']

    rule_loader = Agent[:rule_provider].start(tuple_space_server)
    rule_loader.read_document(@doc)
    write(Tuple[:process_info].new('spec_rule', 'FlowHandler'))

    # start input generators
    gen1 = Agent[:input_generator].start_by_simple(@ts_server, "*.a", 1..10, 1..10)
    gen2 = Agent[:input_generator].start_by_simple(@ts_server, "*.b", 1..10, 1..10)
    gen1.wait_till(:terminated)
    gen2.wait_till(:terminated)
  end

  it 'should find inputs' do
    check_exceptions

    # find input combinations of flow1
    inputs = @doc['flow1'].find_input_combinations(tuple_space_server, "/input")
    inputs.size.should == 1
    a = (1..10).map {|i| read(Tuple[:data].new(name: "#{i}.a"))}
    b = (1..10).map {|i| read(Tuple[:data].new(name: "#{i}.b"))}
    inputs.should.include [a, b]

    # find input combinations of action_a
    inputs = @doc['action_a'].find_input_combinations(tuple_space_server, "/input")
    inputs.size.should == 10
    10.times do |i|
      a = read(Tuple[:data].new(name: "#{i+1}.a"))
      b = read(Tuple[:data].new(name: "#{i+1}.b"))
      inputs.should.include [a, b]
    end
  end

  it 'should make a flow handler' do
    check_exceptions

    # make a handler
    input_comb = @rule.find_input_combinations(@ts_server, "/input")
    base_uri = read(Tuple[:base_uri].any).uri
    input_comb.each do |inputs|
      handler = @rule.make_handler(tuple_space_server, inputs, [])
      handler.should.be.kind_of Rule::FlowHandler
    end
  end

  it 'should execute a flow rule' do
    # start input generators
    gen1 = Agent[:input_generator].start_by_simple(@ts_server, "*.a", 1..10, 1..10)
    gen2 = Agent[:input_generator].start_by_simple(@ts_server, "*.b", 1..10, 1..10)
    gen1.wait_till(:terminated)
    gen2.wait_till(:terminated)
    check_exceptions

    # workers
    worker1 = Agent[:task_worker].start(tuple_space_server)

    # execute
    root = Rule::RootRule.new(@rule.path)
    handler = root.make_handler(tuple_space_server)

    InnocentWhite.debug_mode do
      outputs = handler.execute
      outputs.first.each {|output| puts output }
      outputs.first.size.should == 10
      outputs.fist.each do |output|
        n = File.basename(output.name).to_i
        result = Resource[output.uri].read.to_i
        result.should == n*2*3-1
      end
    end
  end
end

describe 'CountChar' do
  before do
    @ts_server = create_remote_tuple_space_server
    @doc = Document.load(File.open('example/CountChar/CountChar.iw'))
    p @doc
    @rule = @doc['Main']

    rule_loader = Agent[:rule_provider].start(tuple_space_server)
    rule_loader.read_document(@doc)
    write(Tuple[:process_info].new('spec_rule', 'CountChar'))

    # start input generators
    gen = Agent[:input_generator].start_by_dir(tuple_space_server, "example/CountChar/text")
    gen.wait_till(:terminated)
  end

  it 'should make a summary of character counter' do
    check_exceptions

    # workers
    worker1 = Agent[:task_worker].start(tuple_space_server)

    # execute
    root = Rule::RootRule.new(@rule.path)
    handler = root.make_handler(tuple_space_server)

    InnocentWhite.debug_mode do
      outputs = handler.execute
      outputs.first.size.should == 1
    end
  end
end
