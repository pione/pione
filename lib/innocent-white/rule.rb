require 'tempfile'
require 'innocent-white/common'
require 'innocent-white/agent/sync-monitor'
require 'innocent-white/flow-element'

module InnocentWhite
  module Rule
    class ExecutionError < Exception; end
    class UnknownRule < Exception; end

    # Base rule class for flow rule and action rule.
    class BaseRule
      attr_reader :path
      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params
      attr_reader :content

      def initialize(path, inputs, outputs, params, content)
        @path = path
        @inputs = inputs
        @outputs = outputs
        @params = params
        @content = content
      end

      # Return true if the rule has stream input.
      def stream?
        return false
      end

      # Find input data combinations from tuple space server.
      def find_input_combinations(ts_server, domain)
        combinations = _find_input_combinations(ts_server, domain, @inputs, 1, {})
        combinations.map{|c,v| c}
      end

      # Find input data combinations from tuple space server.
      def find_input_combinations_and_variables(ts_server, domain)
        _find_input_combinations(ts_server, domain, @inputs, 1, {})
      end

      # Find output data as tuple form from tuple space server.
      def find_outputs(ts_server, domain, inputs, var)
        names = @outputs.map{|output| output.with_variables(var)}
        return names.map{|name| find_data_by_name(ts_server, domain, name)}
      end

      # Make task data.
      def write_task(ts_server, domain)
        find_input_combinations(ts_server, domain).each do |inputs|
          ts_server.write(Tuple[:task].new(@path, inputs, params))
        end
      end

      def expanded_outputs(var)
        @outputs.map{|output| output.with_variables(var)}
      end

      # Make rule handler from the rule.
      def make_handler(ts_server, inputs, params, opts={})
        klass = self.kind_of?(ActionRule) ? ActionHandler : FlowHandler
        klass.new(ts_server, self, inputs, params, opts)
      end

      def rule_path
        return @path
      end

      def ==(other)
        return false unless @inputs == other.inputs
        return false unless @outputs == other.outputs
        return false unless @params == other.params
        return false unless @content == other.content
        return true
      end

      alias :eql? :==

      def hash
        @inputs.hash + @outputs.hash + @params.hash + @content.hash
      end

      private

      # Find input data combinatioins.
      def _find_input_combinations(ts_server, domain, inputs, index, var)
        # return empty when we reach the recuirsion end
        return [[[],var]] if inputs.empty?

        # expand variables and compile to regular expression
        name = inputs.first.with_variables(var)

        # find an input data by name from tuple space server
        tuples = find_data_by_name(ts_server, domain, name)

        result = []

        # make combinations
        if name.all?
          # case all modifier
          new_var = make_auto_variables_by_all(name, index, tuples, var)
          unless tuples.empty?
            _find_input_combinations(ts_server, domain, inputs[1..-1], index+1, new_var).each do |c,v|
              result << [c.unshift(tuples), v]
            end
          end
        else
          # case each modifier
          tuples.each do |tuple|
            new_var = make_auto_variables_by_each(name, index, tuple, var)
            _find_input_combinations(ts_server, domain, inputs[1..-1], index+1, new_var).each do |c,v|
              result << [c.unshift(tuple), v]
            end
          end
        end

        return result
      end

      # Find data from tuple space server by the name.
      def find_data_by_name(ts_server, domain, name)
        ts_server.read_all(Tuple[:data].new(name: name, domain: domain))
      end

      # Make auto-variables by the name modified 'all'.
      def make_auto_variables_by_all(name, index, tuples, var)
        new_var = var.clone
        new_var["INPUT[#{index}]"] = tuples.map{|t| t.name}.join(DataExpr::SEPARATOR)
        return new_var
      end

      # Make auto-variables by the name modified 'each'.
      def make_auto_variables_by_each(name, index, tuple, var)
        new_var = var.clone
        md = name.match(tuple.name)
        new_var["INPUT[#{index}]"] = tuple.name
        new_var["INPUT[#{index}].URI"] = tuple.uri
        md.to_a.each_with_index do |s, i|
          new_var["INPUT[#{index}].*"] = s if i==1
          new_var["INPUT[#{index}].MATCH[#{i}]"] = s
        end
        return new_var
      end
    end

    class BaseHandler
      include TupleSpaceServerInterface

      attr_reader :rule
      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params
      attr_reader :working_directory
      attr_reader :resource_uri
      attr_reader :task_id
      attr_reader :domain

      def initialize(ts_server, rule, inputs, params, opts={})
        # check arguments
        raise ArgumentError.new(inputs) unless inputs.size == rule.inputs.size

        set_tuple_space_server(ts_server)

        @rule = rule
        @inputs = inputs
        @outputs = []
        @params = params
        @content = rule.content
        @variable_table = {}
        @working_directory = make_working_directory(opts)
        @resource_uri = make_resource_uri(read(Tuple[:base_uri].any).uri)
        @task_id = Util.task_id(@inputs, @params)
        @domain = Util.domain(@rule.path, @inputs, @params)
        make_auto_variables
        sync_inputs
      end

      def ==(other)
        return false unless @rule == other.rule
        return false unless @inputs == other.inputs
        return false unless @outputs == other.outputs
        return false unless @params == other.params
        return true
      end

      alias :eql? :==

      def hash
        @rule.hash + @inputs.hash + @outputs.hash + @params.hash
      end

      private

      # Make working directory.
      def make_working_directory(opts)
        # build directory path
        process_name = opts[:process_name] || "no-process-name"
        process_id = opts[:process_id] || "no-process-id"
        process_dirname = "#{process_name}_#{process_id}"
        task_dirname = "#{@rule.path}_#{Util.task_id(@inputs, @params)}"
        tmpdir = Dir.tmpdir
        basename = File.join(tmpdir, process_dirname, task_dirname)
        # create a directory
        FileUtils.makedirs(basename)
        Dir.mktmpdir(nil, basename)
      end

      def make_resource_uri(base_uri)
        URI(base_uri) + "#{Util.domain(@rule.path, @inputs, @params)}/"
      end

      def sync_inputs
        @inputs.flatten.each do |input|
          filepath = File.join(@working_directory, input.name)
          File.open(filepath, "w+") do |out|
            out.write Resource[URI(input.uri)].read
          end
        end
      end

      def write_output_resource
        @outputs.flatten.each do |output|
          val = File.read(File.join(@working_directory, output.name))
          Resource[output.uri].create(val)
        end
      end

      def write_output_data
        @outputs.flatten.each do |output|
          write(output)
        end
      end

      # Make output tuple by name.
      def make_output_tuple(name)
        Tuple[:data].new(@domain, name, (@resource_uri + name).to_s)
      end

      # Make auto vairables.
      def make_auto_variables
        # inputs
        @rule.inputs.each_with_index do |exp, index|
          make_io_auto_variables(:input, exp, @inputs[index], index+1)
        end

        # outputs: FIXME
        @rule.outputs.each_with_index do |exp, index|
          data = make_output_tuple(exp.with_variables(@variable_table).name)
          make_io_auto_variables(:output, exp, data, index+1)
        end

        # others
        make_other_auto_variables
      end

      # Make input or output auto variables.
      def make_io_auto_variables(type, exp, data, index)
        name = :make_io_auto_variables_by_all if exp.all?
        name = :make_io_auto_variables_by_each if exp.each?
        method(name).call(type, exp, data, index)
      end

      # Make input or output auto variables for 'exist' modified data name expression.
      def make_io_auto_variables_by_each(type, exp, data, index)
        prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
        @variable_table[prefix] = data.name
        @variable_table["#{prefix}.URI"] = data.uri
        if type == :input
          @variable_table["#{prefix}.VALUE"] = Resource[URI(data.uri)].read
        end
        exp.match(data.name).to_a.each_with_index do |s, i|
          @variable_table["#{prefix}.MATCH[#{i}]"] = s
        end
      end

      # Make input or output auto variables for 'all' modified data name expression.
      def make_io_auto_variables_by_all(type, exp, tuples, index)
        # FIXME: output
        return if type == :output
        prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
        @variable_table[prefix] = tuples.map{|t| t.name}.join(':')
      end

      # Make other auto variables.
      def make_other_auto_variables
        @variable_table["WORKING_DIRECTORY"] = @working_directory
        @variable_table["PWD"] = @working_directory
      end
    end
  end
end

require 'innocent-white/rule/flow-rule'
require 'innocent-white/rule/action-rule'
require 'innocent-white/rule/root-rule'
require 'innocent-white/rule/system-rule'
