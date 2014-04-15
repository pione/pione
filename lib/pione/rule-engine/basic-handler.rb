module Pione
  module RuleEngine
    # BasicHandler is a base class for rule handlers.
    class BasicHandler
      include TupleSpace::TupleSpaceInterface
      include Log::MessageLog

      attr_reader :plain_env        # plain environment
      attr_reader :env              # handler's environement
      attr_reader :package_id       # package id
      attr_reader :rule_name        # rule name
      attr_reader :rule_definition  # definition of the handling rule
      attr_reader :rule_condition   # rule condtions
      attr_reader :inputs           # input tuples
      attr_reader :outputs          # output tuples
      attr_reader :param_set        # parameter set
      attr_reader :digest           # handler's digest string
      attr_reader :base_location    # base location
      attr_reader :dry_run          # flag of dry run mode
      attr_reader :domain_id        # domain id
      attr_reader :domain_location  # domain location
      attr_reader :caller_id        # from domain

      # Create a new handler for rule.
      def initialize(space, env, package_id, rule_name, rule_definition, inputs, param_set, domain_id, caller_id)
        ### set tuple space server
        set_tuple_space(space)

        ### set informations
        @plain_env = env
        @env = setup_env(env, param_set)
        @package_id = package_id
        @rule_name = rule_name
        @rule_definition = rule_definition
        @rule_condition = rule_definition.rule_condition_context.eval(@env)
        @inputs = inputs
        @outputs = []
        @param_set = param_set
        @digest = Util::TaskDigest.generate(package_id, rule_name, inputs, param_set)
        @base_location = read!(TupleSpace::BaseLocationTuple.any).location
        @dry_run = begin read!(TupleSpace::DryRunTuple.any).availability rescue false end
        @domain_id = domain_id
        @domain_location = make_location("", @domain_id)
        @caller_id = caller_id
      end

      # Handle the rule and return the outputs.
      def handle
        # make rule and task process log
        process_log(make_task_process_record.merge(transition: "start"))
        process_log(make_rule_process_record.merge(transition: "start"))

        # show begin messages
        user_message(@digest, 0, "==>")
        debug_message("caller: %s" % @caller_id)

        # save domain log
        Log::DomainLog.new(self).save

        # save a domain dump file
        domain_dump_location = @working_directory ? @working_directory :@domain_location
        System::DomainDump.new(env.dumpable).write(domain_dump_location)

        # execute the rule
        outputs = execute

        # publish outputs and finished
        begin
          outputs.flatten.compact.each {|output| write(output)}
          write(TupleSpace::FinishedTuple.new(@domain_id, Util::UUID.generate, :succeeded, outputs))
        rescue Rinda::RedundantTupleError
          write(TupleSpace::FinishedTuple.new(@domain_id, Util::UUID.generate, :error, outputs))
        end

        # show end message
        show_outputs(outputs)
        user_message(@digest, 0, "<==")

        # put rule and task process log
        process_log(make_rule_process_record.merge(transition: "complete"))
        process_log(make_task_process_record.merge(transition: "complete"))
      end

      # Executes the rule.
      def execute
        raise NotImplementError
      end

      # Make location by data name and the domain.
      #
      # @param name [String]
      #   data name
      # @param domain [String]
      #   domain of the data
      # @return [BasicLocation]
      #   the location
      def make_location(name, domain_id)
        if domain_id == "root"
          return @base_location + "./%s" % name
        else
          # make relative path
          pakcage_id, rule_name, task_id = domain_id.split(":")
          path = "./.%s/%s/%s/%s" % [package_id, rule_name, task_id, name]

          # make location
          return @base_location + path
        end
      end

      # Make output data location by the name.
      def make_output_location(name)
        # FIXME: maybe we should not lift output here
        return if @caller_id.nil?

        # get parent domain or root domain
        make_location(name, @caller_id)
      end

      # Make output tuple by the name.
      def make_output_tuple(data_expr)
        name = data_expr.first.name
        location = make_output_location(name)
        TupleSpace::DataTuple.new(name: name, domain: @domain_id, location: location, time: nil)
      end

      # Setup handler's environment. We make a new environment that is
      # introduced a new layer in top of the plain package environment, so we
      # can do any operations safety.
      def setup_env(env, param_set)
        # put new layer
        _env = env.layer
        # set current package id
        _env.set(current_package_id: package_id)
        # merge parameter set
        _env.merge_param_set(param_set)

        ### system environment
        # ENV.each do |key, value|
        #   @variable_table.set(Variable.new("ENV_" + key), PioneString.new(value))
        # end
      end

      # Find outputs from the domain space.
      #
      # @return [void]
      def find_outputs_from_space
        tuples = read_all(TupleSpace::DataTuple.new(domain: @domain_id))
        outputs = []

        @rule_condition.outputs.each_with_index do |condition, i|
          _condition = condition.eval(@env)
          case _condition.distribution
          when :all
            outputs[i] = tuples.find_all {|t| _condition.match(t.name)}
          when :each
            # FIXME
            outputs[i] = tuples.find_all {|t| _condition.match(t.name)}
          end

          # apply touch operation and push the result
          if new_tuples = apply_touch_operation(_condition, outputs[i])
            outputs[i] = new_tuples
          end

          # write data null if needed
          write_data_null(_condition, outputs[i], i)
        end

        return outputs
      end

      # Apply touch operation.
      def apply_touch_operation(condition, tuples)
        _condition = condition.eval(@env)
        if _condition.operation == :touch
          if tuples.empty?
            create_data_by_touch_operation(_condition)
          else
            update_time_by_touch_operation(tuples)
          end
        end
      end

      def create_data_by_touch_operation(condition)
        # NOTE: touch operation applies first piece of data sequence now
        name = condition.pieces.first.pattern
        location = @domain_location + name
        # create a empty file
        location.create("") unless location.exist?
        # FIXME: write a touch tuple
        time = Time.now
        write(TupleSpace::TouchTuple.new(name: name, domain: @domain_id, time: time))
        # FIXME: create an output data tuple
        data_tuple = TupleSpace::DataTuple.new(name: name, domain: @domain_id, location: location, time: time)
        write(data_tuple)
        [data_tuple]
      end

      def update_time_by_touch_operation(tuples)
        fun = lambda do |tuple|
          time = Time.now
          new_data = TupleSpace::DataTuple.new(name: tuple.name, domain: @domain_id, location: tuple.location, time: time)
          write(TupleSpace::TouchTuple.new(name: tuple.name, domain: @domain_id, time: time))
          write(new_data)
          new_data
        end
        tuples.map do |tuple|
          take!(TupleSpace::DataTuple.new(name: tuple.name, domain: @domain_id)) ? fun.call(tuple) : tuple
        end
      end

      # Write a data null tuple if the output condition accepts nonexistence.
      def write_data_null(output, tuples, i)
        if output.accept_nonexistence? and tuples.nil?
          write(TupleSpace::DataNullTuple.new(domain: @domain_id, position: i))
        end
      end

      # Build rule process record.
      def make_rule_process_record
        Log::RuleProcessRecord.new.tap do |record|
          record.name = "&%s:%s" % [@package_id, @rule_name]
          record.rule_type = @rule_definition.rule_type
          if @caller
            caller_package_id, caller_rule_name, caller_task_id = @caller.split(":")
            record.caller = "&%s:%s" % [caller_package_id, caller_rule_name]
          end
        end
      end

      def make_task_process_record
        Log::TaskProcessRecord.new.tap do |record|
          record.name = @digest
          record.package_id = @package_id
          record.rule_name = @rule_name
          record.rule_type = @rule_definition.rule_type
          record.inputs = @inputs.flatten.map{|input| input.name}.join(",")
          record.parameters = @param_set.textize
        end
      end

      # Publish output data tuples.
      def publish_outputs(outputs)
        # output data
      rescue Rinda::RedundantTupleError
        write("finished")
      end

      # Show output tuples as message. This method is used for debugging only.
      def show_outputs(outputs)
        debug_message("Result of %s:" % @digest)
        if outputs
          outputs.each_with_index do |output, i|
            output.each_with_index do |t, ii|
              debug_message("[%s,%s] %s" % [i, ii, t.name], 1)
            end
          end
        else
          debug_message("no outputs", 1)
        end
      end

    end
  end
end

