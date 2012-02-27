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

      # Find input data combinations from tuple space server.
      def find_input_combinations(ts_server, domain)
        _find_input_combinations(ts_server, domain, @inputs, 1, {})
      end

      # Find output data from tuple space server.
      def find_output(ts_server, domain, inputs, var)
        names = @outputs.map{|output| output.with_variables(var)}
        return names.map{|name| find_data_by_name(ts_server, domain, name)}
      end

      # Make task data.
      def write_task(ts_server, domain)
        find_input_combinations(ts_server, domain).each do |inputs|
          ts_server.write(Tuple[:task].new(@path, inputs, params))
        end
      end

      # Make rule handler from the rule.
      def make_handler(base_uri, inputs, params, opts={})
        klass = self.kind_of?(ActionRule) ? ActionHandler : FlowHandler
        klass.new(base_uri, self, inputs, params, opts)
      end

      private

      # Find input data combinatioins.
      def _find_input_combinations(ts_server, domain, inputs, index, var)
        # return empty when reach the recuirsion end
        return [[]] if inputs.empty?

        # expand variables and compile to regular expression
        name = inputs.first.with_variables(var)

        # find an input data by name from tuple space server
        tuples = find_data_by_name(ts_server, domain, name)

        result = []

        # make combinations
        if name.all?
          # case all modifier
          new_var = make_auto_variables_by_all(name, index, tuples, var)
          _find_input_combination(ts_server, domain, inputs[1..-1], index+1, new_var).each do |c|
            result << c.unshift(tuples)
          end
        else
          # case each modifier
          tuples.each do |tuple|
            new_var = make_auto_variables_by_each(name, index, tuple, var)
            _find_input_combinations(ts_server, domain, inputs[1..-1], index+1, new_var).each do |c|
              result << c.unshift(tuple)
            end
          end
        end

        return result
      end

      # Find input data by the name.
      def find_data_by_name(ts_server, domain, name)
        ts_server.read_all(Tuple[:data].new(name: name, domain: domain))
      end

      # Make auto-variables by the name modified 'all'.
      def make_auto_variables_by_all(name, index, tuples, var)
        new_var = var.clone
        new_var["INPUT[#{index}]"] = tuples.map{|t| t.name}.join(',')
        return new_var
      end

      # Make auto-variables by the name modified 'each'.
      def make_auto_variables_by_each(name, index, tuple, var)
        new_var = var.clone
        md = name.match(tuple.name)
        new_var["INPUT[#{index}]"] = tuple.name
        new_var["INPUT[#{index}].URI"] = tuple.uri
        md.to_a.each_with_index do |s, i|
          new_var["INPUT[#{index}].MATCH[#{i}]"] = s
        end
        return new_var
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
        @resource_uri = make_resource_uri(base_uri)
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

      def make_resource_uri(base_uri)
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
          Resource[output.uri].create(val)
        end
      end

      def write_output_data(ts_server)
        @outputs.flatten.each do |output|
          ts_server.write(output)
        end
      end

      # Make output tuple by name.
      def make_output_tuple(name)
        Tuple[:data].new(domain: @domain,
                         name: name,
                         uri: (@resource_uri + name).to_s)
      end

      def find_outputs
        outputs = []
        list = Dir.entries(@working_directory)
        @rule.outputs.each_with_index do |exp, i|
          exp = exp.with_variables(@variable_table)
          if exp.all?
            # case all modifier
            names = list.select {|elt| exp.match(elt)}
            @outputs[i] = names.map{|name| make_output_tuple(name)}
          else
            # case each modifier
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
          data = make_output_tuple(exp.with_variables(@variable_table).name)
          make_io_auto_variables(:output, exp, data, index+1)
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

    class FlowHandler < BaseHandler
      def execute(ts_server)
        apply_rules(ts_server)
        find_outputs
        write_output_resource
        write_output_data(ts_server)
        return @output
      end

      private

      def apply_rules(ts_server)
        @content.each do |caller|
          rule =
            begin
              read(Tuple[:rule].new(rule_path: caller.rule_path), 0)
            rescue Rinda::RequestExpiredError
              write(Tuple[:request_rule].new(caller.rule_path))
              read(Tuple[:rule].new(rule_path: caller.rule_path))
            end
          if rule.status == :known
            
          else
            raise UnkownTask.new(task)
          end
          
        end
      end
    end

    class ActionRule < BaseRule; end

    class ActionHandler < BaseHandler
      # Execute the action.
      def execute(ts_server)
        write_shell_script {|path| shell path}
        find_outputs
        write_output_resource
        write_output_data(ts_server)
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
