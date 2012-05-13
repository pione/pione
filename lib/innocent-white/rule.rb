require 'tempfile'
require 'innocent-white/common'
require 'innocent-white/agent/sync-monitor'
require 'innocent-white/flow-element'

module InnocentWhite
  module Rule
    class ExecutionError < Exception; end
    class UnknownRule < Exception; end

    # Base rule class for flow rule and action rule.
    class BaseRule < InnocentWhiteObject
      attr_reader :path
      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params
      attr_reader :content

      # Create a rule definition object.
      # [+path+] rule path
      # [+inputs+] input expressions
      # [+outputs+] output expressions
      # [+params+] parameters
      # [+content+] rule content
      def initialize(path, inputs, outputs, params, content)
        @path = path
        @inputs = inputs
        @outputs = outputs
        @params = params
        @content = content
      end

      # Make task handler object for the rule.
      def make_handler(ts_server, inputs, params, opts={})
        handler_class.new(ts_server, self, inputs, params, opts)
      end

      # :nodoc:
      def handler_class
        raise NotImplementedError
      end

      # Return rule path.
      def rule_path
        return @path
      end

      # :nodoc:
      def ==(other)
        return false unless @inputs == other.inputs
        return false unless @outputs == other.outputs
        return false unless @params == other.params
        return false unless @content == other.content
        return true
      end

      # :nodoc:
      alias :eql? :==

      # :nodoc
      def hash
        @inputs.hash + @outputs.hash + @params.hash + @content.hash
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

      # Create a new handler for rule.
      def initialize(ts_server, rule, inputs, params, opts={})
        # check arguments
        raise ArgumentError.new(inputs) unless inputs.size == rule.inputs.size

        # set tuple space server
        set_tuple_space_server(ts_server)

        # set informations
        @rule = rule
        @inputs = inputs
        @outputs = []
        @params = params
        @content = rule.content
        @working_directory = make_working_directory(opts)
        @variable_table = VariableTable.new
        @resource_uri = make_resource_uri(read(Tuple[:base_uri].any).uri)
        @task_id = Util.task_id(@inputs, @params)
        @domain = get_handling_domain(opts)

        setup_variable_table
        setup_working_directory
      end

      # :nodoc:
      def ==(other)
        return false unless @rule == other.rule
        return false unless @inputs == other.inputs
        return false unless @outputs == other.outputs
        return false unless @params == other.params
        return true
      end

      # :nodoc:
      alias :eql? :==

      # :nodoc:
      def hash
        @rule.hash + @inputs.hash + @outputs.hash + @params.hash
      end

      private

      def get_handling_domain(opts)
        opts[:domain] || Util.domain(@rule.path, @inputs, @params)
      end

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
        # URI(base_uri) + "#{Util.domain(@rule.path, @inputs, @params)}/"
        URI(base_uri) + "#{@domain}/"
      end

      # Setup variable table. The following variables are introduced in variable
      # table:
      # - input auto variables
      # - output auto variables
      # - working directory
      def setup_variable_table
        @variable_table.make_input_auto_variables(@rule.inputs, @inputs)
        @variable_table.make_output_auto_variables(@rule.outputs, @outputs)
        @variable_table.set("WORKING_DIRECTORY", @working_directory)
        @variable_table.set("PWD", @working_directory)
      end

      # Synchronize input data into working directory.
      def setup_working_directory
        @inputs.flatten.each do |input|
          # get filepath in working directory
          filepath = File.join(@working_directory, input.name)
          # write the file
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
    end
  end
end

require 'innocent-white/rule/flow-rule'
require 'innocent-white/rule/action-rule'
require 'innocent-white/rule/root-rule'
require 'innocent-white/rule/system-rule'
