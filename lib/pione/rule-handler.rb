require 'pione/common'

module Pione
  module RuleHandler
    # Exception class for rule execution failure.
    class RuleExecutionError < StandardError
      def initialize(handler)
        @handler = handler
      end

      def message
        "Execution error when handling the rule '%s': inputs=%s, output=%s, params=%s" % [
          @handler.rule.rule_path,
          @handler.inputs,
          @handler.outputs,
          @handler.params.inspect
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
      attr_reader :base_uri
      attr_reader :task_id
      attr_reader :domain
      attr_reader :variable_table
      attr_reader :call_stack
      attr_reader :resource_hints

      # Create a new handler for rule.
      # [+ts_server+] tuple space server
      # [+rule+] rule instance
      # [+inputs+] input tuples
      # [+opts+] optionals
      def initialize(ts_server, rule, inputs, params, call_stack, resource_hints, opts={})
        # check arguments
        raise ArgumentError.new(inputs) unless inputs.kind_of?(Array)
        raise ArgumentError.new(inputs) unless inputs.size == rule.inputs.size
        raise ArgumentError.new(params) unless params.kind_of?(Parameters)

        # set tuple space server
        set_tuple_space_server(ts_server)

        # set informations
        @rule = rule
        @inputs = inputs
        @outputs = []
        @params = @rule.params.merge(params)
        @original_params = params
        @content = rule.body
        @working_directory = make_working_directory(opts)
        @domain = get_handling_domain(opts)
        @variable_table = VariableTable.new(@params.data)
        @base_uri = read(Tuple[:base_uri].any).uri
        @resource_hints = resource_hints
        @task_id = Util.task_id(@inputs, @params)
        @call_stack = call_stack

        setup_variable_table
        setup_working_directory
      end

      # Puts environment variable into pione variable table.
      def setenv(env)
        env.each do |key, value|
          @variable_table.set(Variable.new("ENV_" + key), PioneString.new(value))
        end
      end

      # Handles the rule.
      def handle
        name = self.class.message_name

        # show begin message
        user_message_begin("Start %s Rule: %s" % [name, handler_digest])

        # call stack
        debug_message("call stack:")
        @call_stack.each_with_index do |domain, i|
          debug_message("%s:%s" % [i, domain], 1)
        end

        outputs = execute

        # show output list
        debug_message("%s Rule %s Result:" % [name, handler_digest])
        @outputs.each_with_index do |output, i|
          if output.kind_of?(Array)
            output.each_with_index do |o, ii|
              debug_message("%s,%s:%s" % [i, ii, o.name], 1)
            end
          else
            debug_message("%s:%s" % [i, output.name], 1)
          end
        end
        # show end message
        user_message_end "End %s Rule: %s" % [name, handler_digest]

        return outputs
      end

      # Executes the rule.
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
          @original_params
        )
      end

      # Make a working directory.
      def make_working_directory(opts)
        # build directory path
        process_name = opts[:process_name] || "no-pname"
        process_id = opts[:process_id] || "no-pid"
        process_dirname = "#{process_name}_#{process_id}"
        task_dirname = Util.domain(
          @rule.expr.package.name,
          @rule.expr.name,
          @inputs,
          @original_params
        )
        tmpdir = CONFIG[:working_dir] ? CONFIG[:working_dir] : Dir.tmpdir
        basename = File.join(tmpdir, process_dirname, task_dirname)
        # create a directory
        FileUtils.makedirs(basename)
        return basename
      end

      # Makes resource uri with resource hint.
      def make_output_resource_uri(name)
        domain = @domain
        hints = @resource_hints.reverse.each do |hint|
          if hint.outputs.any? {|expr| expr.match(name)}
            domain = hint.domain
          else
            break
          end
        end
        URI(@base_uri) + ("./.%s/%s" % [domain, name])
      end

      # Make output tuple by name.
      def make_output_tuple(name)
        uri = make_output_resource_uri(name).to_s
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

      # Returns digest string of this handler.
      def handler_digest
        "%s([%s],[%s])" % [
          @rule.rule_path,
          @inputs.map{|i|
            i.kind_of?(Array) ? "[%s, ...]" % i[0].name : i.name
          }.join(","),
          @params.data.map{|k,v| "%s:%s" % [k.name, v.textize]}.join(",")
        ]
      end

    end
  end
end

require 'pione/rule-handler/flow-handler'
require 'pione/rule-handler/action-handler'
require 'pione/rule-handler/root-handler'
require 'pione/rule-handler/system-handler'
