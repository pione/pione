require 'pione/common'
require 'pione/agent/sync-monitor'

module Pione
  module RuleHandler
    class RuleExecutionError < StandardError
      def initialize(handler)
        @handler = handler
      end

      def message
        "Execution error when handling the rule '%s' inputs=%s" % [
          @handler.rule.rule_path,
          @handler.inputs
        ]
      end
    end

    class UnknownRule < StandardError; end

    # BaseHandler is a base class for rule handlers.
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
      attr_reader :variable_table

      # Create a new handler for rule.
      # [+ts_server+] tuple space server
      # [+rule+] rule instance
      # [+inputs+] input tuples
      # [+opts+] optionals
      def initialize(ts_server, rule, inputs, params, opts={})
        # check arguments
        raise ArgumentError.new(inputs) unless inputs.size == rule.inputs.size
        raise ArgumentError.new(params) unless params.kind_of?(Parameters)

        # set tuple space server
        set_tuple_space_server(ts_server)

        # set informations
        @rule = rule
        @inputs = inputs
        @outputs = []
        @params = params
        @content = rule.body
        @working_directory = make_working_directory(opts)
        @domain = get_handling_domain(opts)
        @variable_table = VariableTable.new
        @resource_uri = make_resource_uri(read(Tuple[:base_uri].any).uri)
        @task_id = Util.task_id(@inputs, @params)

        setup_variable_table
        setup_working_directory
      end

      def execute
        raise NotImplementError
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

      # Return the domain.
      def get_handling_domain(opts)
        opts[:domain] || Util.domain(
          @rule.expr.package.name,
          @rule.expr.name,
          @inputs,
          @params
        )
      end

      # Make a working directory.
      def make_working_directory(opts)
        # build directory path
        process_name = opts[:process_name] || "no-process-name"
        process_id = opts[:process_id] || "no-process-id"
        process_dirname = "#{process_name}_#{process_id}"
        task_dirname = "%s-%s_%s" % [
          @rule.expr.package.name,
          @rule.expr.name,
          Util.task_id(@inputs, @params)
        ]
        tmpdir = Dir.tmpdir
        basename = File.join(tmpdir, process_dirname, task_dirname)
        # create a directory
        FileUtils.makedirs(basename)
        Dir.mktmpdir(nil, basename)
      end

      def make_resource_uri(base_uri)
        URI(base_uri) + "./#{@domain}/"
      end

      # Make output tuple by name.
      def make_output_tuple(name)
        uri = (@resource_uri + name).to_s
        Tuple[:data].new(name: name, domain: @domain, uri: uri, time: nil)
      end

      # Setup variable table. The following variables are introduced in variable
      # table:
      # - input auto variables
      # - output auto variables
      # - working directory
      def setup_variable_table
        @variable_table.make_input_auto_variables(@rule.inputs, @inputs)
        outputs = @rule.outputs.map {|expr| expr.eval(@variable_table) }
        output_tuples = outputs.map {|expr| make_output_tuple(expr.name) }
        @variable_table.make_output_auto_variables(outputs, output_tuples)
        @variable_table.set(
          Variable.new("WORKING_DIRECTORY"),
          PioneString.new(@working_directory)
        )
        @variable_table.set(
          Variable.new("PWD"),
          PioneString.new(@working_directory)
        )
      end

      # Synchronize input data into working directory.
      def setup_working_directory
        @inputs.flatten.each do |input|
          # get filepath in working directory
          filepath = File.join(@working_directory, input.name)
          # write the file
          File.open(filepath, "w+") do |out|
            out.write(Resource[URI(input.uri)].read)
          end
        end
      end
    end
  end
end

require 'pione/rule-handler/flow-handler'
require 'pione/rule-handler/action-handler'
require 'pione/rule-handler/root-handler'
require 'pione/rule-handler/system-handler'
