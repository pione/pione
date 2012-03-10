require 'tempfile'
require 'innocent-white/common'
require 'innocent-white/agent/sync-monitor'

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

      # Find input data combinations from tuple space server.
      def find_input_combinations(ts_server, domain)
        combinations = _find_input_combinations(ts_server, domain, @inputs, 1, {})
        combinations.map{|c,v| c}
      end

      # Find input data combinations from tuple space server.
      def find_input_combinations_and_variables(ts_server, domain)
        _find_input_combinations(ts_server, domain, @inputs, 1, {})
      end

      # Find output data from tuple space server.
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
        # return empty when reach the recuirsion end
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

      # Find input data by the name.
      def find_data_by_name(ts_server, domain, name)
        ts_server.read_all(Tuple[:data].new(name: name, domain: domain))
      end

      # Make auto-variables by the name modified 'all'.
      def make_auto_variables_by_all(name, index, tuples, var)
        new_var = var.clone
        new_var["INPUT[#{index}]"] = tuples.map{|t| t.name}.join(':')
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

    class FlowRule < BaseRule
      def action?
        false
      end

      def flow?
        true
      end
    end

    module FlowParts
      class Base < InnocentWhiteObject; end

      class Call < Base
        attr_reader :rule_path

        def initialize(rule_path, sync_mode=false)
          @rule_path = rule_path
          @sync_mode = sync_mode
        end

        # Return sync mode version caller.
        def with_sync
          self.class.new(@rule_path, true)
        end

        # Return true if sync mode.
        def sync_mode?
          @sync_mode
        end
      end

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
      def execute
        puts ">>> Start Flow Rule #{@rule.path}" if debug_mode?

        apply_rules
        find_outputs

        # check output
        if @rule.outputs.size > 0 and not(@rule.outputs.size == @outputs.size)
          raise ExecutionError.new(self)
        end

        if debug_mode?
          puts "Flow Rule #{@rule.path} Result:"
          @outputs.each {|output| puts "  #{output}"}
        end

        puts ">>> End Flow Rule #{@rule.path}" if debug_mode?

        return @outputs
      end

      # Return true if the handler is waiting finished tuple.
      def finished_waiting?
        # FIXME
        false
      end

      private

      # Find outputs from the domain of tuple space.
      def find_outputs
        outputs = []
        @rule.outputs.each_with_index do |exp, i|
          exp = exp.with_variables(@variable_table)
          list = read_all(Tuple[:data].new(domain: @domain))
          if exp.all?
            # case all modifier
            names = list.select {|elt| exp.match(elt.name)}
            unless names.empty?
              @outputs[i] = names
            end
          else
            # case each modifier
            name = list.find {|elt| exp.match(elt.name)}
            if name
              @outputs[i] = name
            end
          end
        end
      end

      # Apply target data to rules.
      def apply_rules
        puts ">>> Start Rule Application: #{@rule.path}" if debug_mode?

        # SyncMonitor
        Agent[:sync_monitor].start(tuple_space_server, self) do
          cont = true
          while cont do
            inputs = find_applicable_input_combinations
            update_targets = find_update_targets(inputs)
            unless update_targets.empty?
              # distribute task
              handle_task(update_targets)
            else
              # finish application
              cont = false
            end
          end
        end

        puts ">>> End Rule Application: #{@rule.path}" if debug_mode?
      end

      # Check application inputs.
      def find_applicable_input_combinations
        inputs = []
        @content.each do |caller|
          # get target rule
          rule =
            begin
              read(Tuple[:rule].new(rule_path: caller.rule_path), 0)
            rescue Rinda::RequestExpiredError
              write(Tuple[:request_rule].new(caller.rule_path))
              read(Tuple[:rule].new(rule_path: caller.rule_path))
            end
          # check rule status and find combinations
          if rule.status == :known
            combinations = rule.content.find_input_combinations_and_variables(tuple_space_server, @domain)
            inputs << [rule, combinations] unless combinations.nil?
          else
            raise UnknownRule.new(caller.rule_path)
          end
        end
        return inputs
      end

      def find_update_targets(inputs)
        targets = []
        inputs.each do |rule, combinations|
          combinations.each do |combination, var|
            current_outputs = rule.content.find_outputs(tuple_space_server, @domain, combination, var)
            if current_outputs.include?([])
              targets << [rule, combination, var]
            end
          end
        end
        return targets
      end

      def handle_task(targets)
        # FIXME: rewrite by using fiber
        thgroup = ThreadGroup.new

        puts ">>> Start Task Distribution: #{@rule.path}" if debug_mode?

        targets.each do |rule, combination, var|
          thread = Thread.new do
            # task domain
            task_domain = Util.domain(rule.rule_path, combination, [])

            # sync monitor
            #if rule.sync?
            #  names = rule.expanded_outputs(var)
            #  write(Tuple[:sync_target].new(src: task_domain, dest: @domain, names: names))
            #end

            # copy input data from the handler domain to task domain
            copy_data_into_domain(combination.flatten, task_domain)

            # FIXME: params is not supportted now
            write(Tuple[:task].new(rule.rule_path, combination, []))

            # wait to finish the work
            finished = read(Tuple[:finished].new(domain: task_domain))
            puts "task finished: #{finished}" if debug_mode?

            # copy data from task domain to this domain
            if finished.status == :succeeded
              #unless sync_mode?
                # copy output data from task domain to the handler domain
                copy_data_into_domain(finished.outputs, @domain)
              #end
            end
          end
          thgroup.add(thread)
        end

        # wait to finish threads
        thgroup.list.each {|th| th.join}

        puts ">>> End Task Distribution: #{@rule.path}" if debug_mode?
      end

      def finalize_rule_application(sync_monitor)
        # stop sync monitor
        sync_monitor.terminate
      end

      # Copy data into specified domain
      def copy_data_into_domain(orig_data, new_domain)
        new_data = orig_data.flatten
        new_data.each do |data|
          data.domain = new_domain
        end
        new_data.each {|data| write(data)}
      end
    end

    class ActionRule < BaseRule
      def action?
        true
      end

      def flow?
        false
      end
    end

    class ActionHandler < BaseHandler
      # Execute the action.
      def execute
        stdout = write_shell_script {|path| shell path}
        write_output_from_stdout(stdout)
        find_outputs
        write_output_resource
        write_output_data
        return @outputs
      end

      private

      def write_output_from_stdout(stdout)
        @rule.outputs.each do |output|
          if output.stdout?
            name = output.with_variables(@variable_table).name
            filepath = File.join(@working_directory, name)
            File.open(filepath, "w+") do |out|
              out.write stdout
            end
            break
          end
        end
      end

      # Write shell script to the tempfile.
      def write_shell_script(&b)
        file = File.open(File.join(@working_directory,"sh"), "w+")
        file.print(Util.expand_variables(@rule.content, @variable_table))
        if debug_mode?
          puts "[#{file.path}]"
          puts "SH-------------------------------------------------------"
          puts Util.expand_variables(@rule.content, @variable_table)
          puts "-------------------------------------------------------SH"
        end
        file.close
        FileUtils.chmod(0700,file.path)
        return b.call(file.path)
      end

      # Call shell script of the path.
      def shell(path)
        scriptname = File.basename(path)
        `cd #{@working_directory}; ./#{scriptname}`
      end

      # Find outputs from working directory.
      def find_outputs
        outputs = []
        list = Dir.entries(@working_directory)
        @rule.outputs.each_with_index do |exp, i|
          exp = exp.with_variables(@variable_table)
          if exp.all?
            # case all modifier
            names = list.select {|elt| exp.match(elt)}
            unless names.empty?
              @outputs[i] = names.map{|name| make_output_tuple(name) unless name.empty?}
            end
          else
            # case each modifier
            name = list.find {|elt| exp.match(elt)}
            if name
              @outputs[i] = make_output_tuple(name)
            end
          end
        end
      end
    end

    class RootRule < FlowRule
      def initialize(rule_path)
        inputs  = [DataExp.all("*")]
        outputs = [DataExp.all("*").except("{$INPUT[1]}")]
        content = [FlowParts::Call.new(rule_path)]
        super(nil, inputs, outputs, [], content)
        @path = 'root'
        @domain = '/root'
      end

      # Make rule handler from the rule.
      def make_handler(ts_server)
        input_combinations = find_input_combinations(ts_server, "/input")
        inputs = input_combinations.first
        RootHandler.new(ts_server, self, inputs, [], {})
      end
    end

    class RootHandler < FlowHandler
      def execute
        puts ">>> Start Root Rule Execution" if debug_mode?
        copy_data_into_domain(@inputs.flatten, @domain)
        result = super
        copy_data_into_domain(@outputs.flatten, '/output')
        # sync_output
        puts ">>> End Root Rule Execution" if debug_mode?
        return result
      end
    end

  end
end
