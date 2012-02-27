require 'tempfile'
require 'innocent-white/common'

module InnocentWhite
  module Rule
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

      # Find input data from tuple space server.
      def find_inputs(ts_server, domain)
        _find_inputs(ts_server, domain, @inputs, 1, {})
      end

      # Find output data from tuple space server.
      def find_outputs(ts_server, domain, inputs)
        # FIXME
      end

      def make_task(ts_server)
        find_inputs(ts_server, domain).each do |_inputs|
          _outputs = find_outputs(ts_server, @domain)
          Tuple[:task].new(@rule_path, _inputs, outputs, params, content)
        end
      end

      # Make rule handler from the rule.
      def make_handler(inputs, params, opts={})
        klass = self.kind_of?(ActionRule) ? ActionHandler : FlowHandler
        klass.new(self, inputs, params, opts)
      end

      private

      def _find_inputs(ts_server, domain, _inputs, index, var)
        return [[]] if _inputs.empty?

        # expand variables and compile to regular expression
        input = _inputs.first.with_variables(var)

        # find an input from tuple space server
        tuples = _find_input(ts_server, domain, input)

        result = []

        if input.all?
          rest = _find_inputs(ts_server, domain, _inputs[1..-1], index+1, var.clone)
        else
          # find rest inputs recursively
          tuples.each do |tuple|
            make_auto_variables_by_each(input, index, tuple, var)
            rest = _find_inputs(ts_server, domain, _inputs[1..-1], index+1, var.clone)
            rest.each {|r| result << r.unshift(tuple) }
          end
        end

        return result
      end

      def _find_input(ts_server, domain, input_name)
        req = Tuple[:data].new(name: input_name, domain: domain)
        ts_server.read_all(req)
      end

      def make_auto_variables_by_each(input, index, tuple, var)
        md = input.match(tuple.name)
        var["INPUT[#{index}]"] = tuple.name
        var["INPUT[#{index}].URI"] = tuple.uri
        md.to_a.each_with_index do |s, i|
          var["INPUT[#{index}].MATCH[#{i}]"] = s
        end
      end

    end

    class BaseHandler
      attr_reader :working_directory

      def initialize(base_uri, rule, inputs, params, opts={})
        # check arguments
        raise ArugmentError unless inputs.size == rule.inputs.size

        @rule = rule
        @inputs = inputs
        @outputs = []
        @params = params
        @variable_table = {}
        @working_directory = make_working_directory(opts)
        @resource_uri = make_resource_uri
        make_auto_variables
        sync_inputs
      end

      private

      def make_working_directory(opts)
        process_name = opts[:process_name] || "no-process-name"
        process_id = opts[:process_id] || "no-process-id"
        process_dirname = "#{process_name}_#{process_id}"
        task_dirname = "#{@rule.path}_#{Util.task_id(@inputs, @params)}"
        tmpdir = Dir.tmpdir
        basename = File.join(tmpdir, process_dirname, task_dirname)
        FileUtils.makedirs(basename)
        Dir.mktmpdir(nil, basename)
      end

      def make_resource_uri
        domain = "#{@rule.path}_#{Util.task_id(@inputs, @params)}"
        URI(base_uri) + "#{domain}/"
      end

      def sync_inputs
        @inputs.each do |input|
          filepath = File.join(@working_directory, input.name)
          File.open(filepath, "w+") do |out|
            out.write Resource[URI(input.uri)].read
          end
        end
      end

      def write_output_resource
        @outputs.flatten.each do |output|
          val = File.read(File.join(@working_directory, output.name))
          Resource[output.uri].write(val)
        end
      end

      def make_output_tuple(name)
        Tuple[:data].new(domain: @domain,
                         name: name,
                         uri: @resource_uri + name)
      end

      def find_outputs
        outputs = []
        list = Dir.entries(@working_directory)
        @rule.outputs.each_with_index do |exp, i|
          if exp.all?
            names = list.select {|elt| exp.match(elt)}
            @outputs[i] = names.map{|name| make_output_tuple(name)}
          else
            name = list.find {|elt| exp.match(elt)}
            @outputs[i] = make_output_tuple(name)
          end
        end
      end

      # Make auto vairables.
      def make_auto_variables
        # inputs
        @rule.inputs.each_with_index do |exp, index|
          make_io_auto_variables(:input, exp, @inputs[index], index+1)
        end

        # outputs
        @rule.outputs.each_with_index do |exp, index|
          # make_io_auto_variables(:output, exp, @outputs[index], index+1)
        end

        # others
        make_other_auto_variables
      end

      # Make input or output auto variables.
      def make_io_auto_variables(type, exp, data, index)
        name = exp.all? ? :make_io_auto_variables_by_all : :make_io_auto_variables_by_exist
        method(name).call(type, exp, data, index)
      end

      # Make input or output auto variables for 'exist' modified data name expression.
      def make_io_auto_variables_by_exist(type, exp, data, index)
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
        prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
        @variable_table[prefix] = tuples.map{|t| t.name}.join(",")
      end

      # Make other auto variables.
      def make_other_auto_variables
        @variable_table["WORKING_DIRECTORY"] = @working_directory
        @variable_table["PWD"] = @working_directory
      end
    end

    class FlowRule < BaseRule
    end

    module FlowParts
      class Base < InnocentWhiteObject

      end

      class Call < Base
        attr_reader :rule_path

        def initialize(rule_path)
          @rule_path = rule_path
        end
      end

      class CallWithSync < Call; end

      class Condition
        attr_reader :condition
        attr_reader :true_expr
        attr_reader :false_expr
      end

      class Assignment
        attr_reader :variable
        attr_reader :content
      end
    end

    class ActionRule < BaseRule
    end

    class ActionHandler < BaseHandler
      # Execute the action.
      def execute
        write_shell_script {|path| shell path}
        find_outputs.each
        write_output_resource
        return @outputs
      end

      private

      # Write shell script to the tempfile.
      def write_shell_script(&b)
        file = File.open(File.join(@working_directory,"sh"), "w+")
        file.print(Util.expand_variables(@rule.content, @variable_table))
        file.close
        FileUtils.chmod(0700,file.path)
        return b.call(file.path)
      end

      # Call shell script of the path.
      def shell(path)
        scriptname = File.basename(path)
        `cd #{@working_directory}; ./#{scriptname}`
      end
    end

  end
end
