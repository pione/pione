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
          @handler.rule.path,
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
      attr_reader :original_params
      attr_reader :base_location
      attr_reader :dry_run
      attr_reader :domain
      attr_reader :variable_table
      attr_reader :call_stack
      attr_reader :domain_location
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
        raise ArgumentError.new(inputs) unless inputs.size == rule.condition.inputs.size
        raise ArgumentError.new(params) unless params.kind_of?(Parameters)

        # set tuple space server
        set_tuple_space_server(ts_server)

        # set informations
        @rule = rule
        @inputs = inputs
        @outputs = []
        @params = @rule.condition.params.merge(params)
        @original_params = params
        @content = rule.body
        @domain = get_handling_domain(opts)
        @variable_table = VariableTable.new(@params.data)
        @base_location = read!(Tuple[:base_location].any).location
        @dry_run = begin read!(Tuple[:dry_run].any).availability rescue false end
        @call_stack = call_stack
        @domain_location = make_location("", @domain)

        caller = @call_stack[-1]

        # build rule process record
        @rule_process_record = Log::RuleProcessRecord.new.tap do |record|
          record.name = "&%s:%s" % [@rule.package_name, @rule.name]
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
          record.rule_name = @rule.path
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
          # @variable_table.set(Variable.new("ENV_" + key), PioneString.new(value))
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
        user_message(handler_digest, 0, "==>")

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
        user_message(handler_digest, 0, "<==")

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

      # Save domain information file.
      #
      # @return [void]
      def save_rule_condition_infos
        Log::DomainInfo.new(self).save
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
        opts[:domain] || Util::DomainID.generate(@rule, @inputs, @original_params)
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
      # @param expr [DataExpr]
      #   data name
      # @return [Tuple::DataTuple]
      #   data tuple
      def make_output_tuple(data_expr)
        name = data_expr.first.name
        location = make_output_location(name)
        Tuple[:data].new(name: name, domain: @domain, location: location, time: nil)
      end

      # Setup variable table. The following variables are introduced in variable
      # table:
      # - input auto variables
      # - output auto variables
      def setup_variable_table
        @variable_table.make_input_auto_variables(@rule.condition.inputs, @inputs)
        outputs = @rule.condition.outputs.map {|expr| expr.eval(@variable_table) }
        output_tuples = outputs.map {|expr| make_output_tuple(expr) }
        @variable_table.make_output_auto_variables(outputs, output_tuples)
      end

      # Returns digest string of this handler.
      def handler_digest
        params = @params.data.select{|k,_|
          not(k.toplevel?)
        }.map{|k,v| "%s:%s" % [k.name, v.textize]}.join(",")
        "%s([%s],{%s})" % [
          @rule.path,
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

      # Find outputs from the domain.
      #
      # @return [void]
      def find_outputs
        tuples = read_all(Tuple[:data].new(domain: @domain))
        @rule.condition.outputs.each_with_index do |output, i|
          output = output.eval(@variable_table)
          case output.distribution
          when :all
            @outputs[i] = tuples.find_all {|data| output.match(data.name)}
          when :each
            # FIXME
            @outputs[i] = tuples.find {|data| output.match(data.name)}
          end

          # apply touch operation and push the result
          if tuple = apply_touch_operation(output, @outputs[i])
            @outputs[i] = tuple
          end

          # write data null if needed
          write_data_null(output, @outputs[i], i)
        end
      end

      # Apply touch operation.
      def apply_touch_operation(output, tuples)
        if output.touch? and tuples.nil?
          location = @domain_location + output.name
          location.create("") unless location.exist?
          Tuple[:data].new(name: output.name, domain: @domain, location: location)
        end
      end

      # Write a data null tuple if the output condition accepts nonexistence.
      def write_data_null(output, tuples, i)
        if output.accept_nonexistence? and tuples.nil?
          write(Tuple::DataNullTuple.new(domain: @domain, position: i))
        end
      end
    end
  end
end

