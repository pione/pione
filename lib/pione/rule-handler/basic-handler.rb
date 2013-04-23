module Pione
  # RuleHandler is a handler for rule application.
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

    # BasicHandler is a base class for rule handlers.
    class BasicHandler
      include TupleSpaceServerInterface

      attr_reader :rule
      attr_reader :inputs
      attr_reader :outputs
      attr_reader :params
      attr_reader :base_location
      attr_reader :task_id
      attr_reader :domain
      attr_reader :variable_table
      attr_reader :call_stack
      attr_reader :rule_process_record
      attr_reader :task_process_record

      # Create a new handler for rule.
      #
      # @param [TupleSpaceServer] ts_server
      #   tuple space server
      # @param [Rule] rule
      #   rule instance
      # @param [Array<Data,Array<Data>>] inputs
      #   input tuples
      # @param [Hash] opts
      #   optionals
      def initialize(ts_server, rule, inputs, params, call_stack, opts={})
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
        @domain = get_handling_domain(opts)
        @variable_table = VariableTable.new(@params.data)
        @base_location = read!(Tuple[:base_location].any).location
        @dry_run = begin read!(Tuple[:dry_run].any).availability rescue false end
        @task_id = ID.task_id(@inputs, @params)
        @call_stack = call_stack
        @domain_location = make_location("", @domain)

        caller = @call_stack[-1]

        # build rule process record
        @rule_process_record = Log::RuleProcessRecord.new.tap do |record|
          record.name = "&%s:%s" % [@rule.expr.package.name, @rule.expr.name]
          record.rule_type = @rule.rule_type
          record.caller = caller.split("_").first.tap do |dname|
            if dname.include?("-")
              package, name = dname.split("-")
              break "&%s:%s" % [package, name]
            else
              break "&root:Root"
            end
          end if caller
        end

        # build task process record
        @task_process_record = Log::TaskProcessRecord.new.tap do |record|
          record.name = handler_digest
          record.rule_name = "&%s:%s" % [@rule.expr.package.name, @rule.expr.name]
          record.rule_type = @rule.rule_type
          record.inputs = @inputs.flatten.map{|input| input.name}.join(",")
          record.parameters = @params.textize
        end

        setup_variable_table
      end

      # Put environment variable into pione variable table.
      #
      # @param [Hash{String => String}] env
      #   environment table
      # @return [void]
      def setenv(env)
        env.each do |key, value|
          @variable_table.set(Variable.new("ENV_" + key), PioneString.new(value))
        end
      end

      # Handle the rule and returns the outputs.
      #
      # @return [Array<Data,Array<Data>>]
      #   outputs
      def handle
        # put rule and task process log
        process_log(@task_process_record.merge(transition: "start"))
        process_log(@rule_process_record.merge(transition: "start"))

        name = self.class.message_name

        # show begin message
        user_message_begin("Start %s Rule: %s" % [name, handler_digest])

        # call stack
        debug_message("call stack:")
        @call_stack.each_with_index do |domain, i|
          debug_message("%s:%s" % [i, domain], 1)
        end

        # save rule condition informations
        save_rule_condition_infos

        # execute the rule
        outputs = execute

        # show output list
        debug_message("%s Rule %s Result:" % [name, handler_digest])

        @outputs.compact.each_with_index do |output, i|
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

        # put rule and task process log
        process_log(@rule_process_record.merge(transition: "complete"))
        process_log(@task_process_record.merge(transition: "complete"))

        return outputs.compact
      end

      # Returns true if it is root rule handler.
      # @return [Boolean]
      #   true if it is root rule handler
      def root?
        self.kind_of?(RootHandler)
      end

      # @api private
      def ==(other)
        return false unless @rule == other.rule
        return false unless @inputs == other.inputs
        return false unless @outputs == other.outputs
        return false unless @params == other.params
        return true
      end

      # @api private
      alias :eql? :==

      # @api private
      def hash
        @rule.hash + @inputs.hash + @outputs.hash + @params.hash
      end

      private

      # Save rule informations.
      #
      # @return [void]
      def save_rule_condition_infos
        info = {}
        info["uname"] = `uname -a`.chomp
        info["params"] = @params.textize
        info["original_params"] = @original_params.textize
        info["inputs"] = "[%s]" % @inputs.map{|input| input.to_s}.join(", ")
        info["domain"] = @domain
        info["domain_location"] = @domain_location.inspect
        info["task_id"] = @task_id.to_s
        info["dry_run"] = @dry_run.to_s
        text = "== %s\n\n" % Time.now
        text << info.map{|key, val| "- %s: %s" % [key,val]}.join("\n")
        text << "\n\n"
        (@domain_location + ".rule_info").append(text)
      end

      # Executes the rule.
      #
      # @return [Array<Data,Array<Data>>]
      #   outputs
      # @api private
      def execute
        raise NotImplementError
      end

      # Return the domain.
      def get_handling_domain(opts)
        opts[:domain] || ID.domain_id(
          @rule.expr.package.name,
          @rule.expr.name,
          @inputs,
          @original_params
        )
      end

      # Make location by data name and the domain.
      #
      # @param name [String]
      #   data name
      # @param domain [String]
      #   domain of the data
      # @return [BasicLocation]
      #   the location
      def make_location(name, domain)
        if domain == "root" || domain.nil?
          return @base_location + "./%s" % name
        else
          # make relative path
          rule_name = domain.split("_")[0..-2].join("_")
          digest = domain.split("_").last
          path = "./.%s/%s/%s" % [rule_name, digest, name]

          # make location
          return @base_location + path
        end
      end

      # Make output data location by the name.
      #
      # @param name [String]
      #   data name
      # @return [BasicLocation]
      #   output data location
      def make_output_location(name)
        # get parent domain or root domain
        make_location(name, @call_stack.last)
      end

      # Make output tuple by the name.
      #
      # @param name [String]
      #   data name
      # @return [Tuple::DataTuple]
      #   data tuple
      def make_output_tuple(name)
        location = make_output_location(name)
        Tuple[:data].new(name: name, domain: @domain, location: location, time: nil)
      end

      # Setup variable table. The following variables are introduced in variable
      # table:
      # - input auto variables
      # - output auto variables
      def setup_variable_table
        @variable_table.make_input_auto_variables(@rule.inputs, @inputs)
        outputs = @rule.outputs.map {|expr| expr.eval(@variable_table) }
        output_tuples = outputs.map {|expr| make_output_tuple(expr.name) }
        @variable_table.make_output_auto_variables(outputs, output_tuples)
      end

      # Returns digest string of this handler.
      def handler_digest
        params = @params.data.select{|k,_|
          not(k.toplevel?)
        }.map{|k,v| "%s:%s" % [k.name, v.textize]}.join(",")
        "%s([%s],{%s})" % [
          @rule.rule_path,
          @inputs.map{|i|
            if i.kind_of?(Array)
              i.empty? ? "[]" : "[%s, ...]" % i[0].name
            else
              i.name
            end
          }.join(","),
          params
        ]
      end

    end
  end
end

