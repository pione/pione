module Pione
  module RuleHandler
    # FlowHandler is a rule handler for flow elements.
    class FlowHandler < BasicHandler
      def self.message_name
        "Flow"
      end

      def initialize(*args)
        super
        @data_finder = DataFinder.new(tuple_space_server, @domain)
        @finished = []
      end

      # Start to process flow elements.
      #
      # @return [void]
      def execute
        # restore data tuples from domain_location
        restore_data_tuples_from_domain_location
        # rule application
        apply_rules(@rule.body.eval(@variable_table).elements)
        # find outputs
        find_outputs
        # lift output data from child domains to this domain
        lift_output_data
        # check output validation
        validate_outputs

        return @outputs
      end

      private

      # Restore data tuples from the domain location. This reads files in the
      # location and write it as data tuples.
      #
      # @return [void]
      def restore_data_tuples_from_domain_location
        dir = root? ? @base_location : @base_location + (".%s/%s" % @domain.split("_"))
        if dir.exist?
          dir.entries.each do |location|
            unless location.basename[0] == "."
              write(Tuple[:data].new(@domain, location.basename, location, location.mtime))
            end
          end
        end
      end

      # Apply input data to rules.
      #
      # @param callees [Array<CallRule>]
      #   elements of call rule lines
      # @return [void]
      def apply_rules(callees)
        user_message_begin("Start Rule Application: %s" % handler_digest)

        while true do
          # find updatable rule applications
          applications = select_updatables(find_applicable_rules(callees))

          # check wheather applications completed
          break if applications.empty?

          # push tasks into tuple space
          distribute_tasks(applications)
        end

        user_message_end("End Rule Application: %s" % handler_digest)
      end

      # Find applicable rules with inputs and variables.
      #
      # @param callees [Array<CallRule>]
      #   callee rules
      def find_applicable_rules(callees)
        callees = callees.inject([]) do |list, callee|
          # evaluate callee by handling rule context and expand compositional
          # rule expressions as simple rule expressions
          list + callee.eval(@variable_table).expr.to_set.to_a.map{|expr| CallRule.new(expr)}
        end

        # ticket check
        callees = callees.inject([]) do |list, callee|
          target = nil
          # check if tickets exist in the domain
          names = callee.expr.input_ticket_expr.names
          if not(names.empty?)
            if names.all? {|name| read!(Tuple[:ticket].new(@domain, name))}
              target = callee
            end
          else
            target = callee
          end
          target ? list << callee : list
        end

        callees.inject([]) do |combinations, callee|
          # find callee rule
          rule = find_callee_rule_tuple(callee).content

          # update callee parameters
          @variable_table.variables.each do |var|
            val = @variable_table.get(var)
            unless val == UndefinedValue.new
              if rule.params.keys.include?(var)
                callee.expr.params.set_safety!(var, val)
              end
            end
          end

          # eval callee rule by the context
          vtable = callee.expr.params.eval(@variable_table).as_variable_table
          rule = rule.eval(vtable)

          # check rule status and find combinations
          @data_finder.find(:input, rule.inputs, vtable).each do |res|
            combinations << [
              callee,
              rule,
              res.combination,
              res.variable_table
            ]
          end

          # find next
          combinations.uniq
        end
      end

      # Find the rule tuple of the callee.
      #
      # @param callee [CallRule]
      #   callee rule
      # @return [RuleTuple]
      #   rule tuple
      def find_callee_rule_tuple(callee)
        if rule = read!(Tuple[:rule].new(rule_path: callee.rule_path))
          return rule
        else
          write(Tuple[:request_rule].new(callee.rule_path))
          return read(Tuple[:rule].new(rule_path: callee.rule_path))
        end
      end

      # Find inputs and variables for flow element rules.
      def select_updatables(combinations)
        combinations.select do |callee, rule, inputs, vtable|
          # task domain
          task_domain = ID.domain_id3(rule, inputs, callee)

          # import finished tuples's data
          import_finished_outputs(task_domain)

          # find outputs combination
          outputs_combination = @data_finder.find(
            :output,
            rule.outputs.map{|output| output.eval(vtable)},
            vtable
          ).map{|r| r.combination }

          # no outputs combination means empty list
          outputs_combination = [[]] if outputs_combination.empty?

          # check update criterias
          outputs_combination.any?{|outputs|
            UpdateCriteria.satisfy?(rule, inputs, outputs, vtable)
          }
        end
      end

      # Distribute tasks.
      #
      # @param [Array] applications
      #   application informations
      # @return [void]
      def distribute_tasks(applications)
        user_message_begin("Start Task Distribution: %s" % handler_digest)
        canceled = []

        process_log(@task_process_record.merge(transition: "suspend"))
        process_log(@rule_process_record.merge(transition: "suspend"))

        applications.uniq.each do |callee, rule, inputs, vtable|
          # task domain
          task_domain = ID.domain_id3(rule, inputs, callee)

          # make a task tuple
          task = Tuple[:task].new(
            rule.rule_path,
            inputs,
            callee.expr.params,
            rule.features,
            task_domain,
            @call_stack + [@domain] # current call stack + caller
          )

          # check if same task exists
          begin
            if need_to_process_task?(task)
              # copy input data from the handler domain to task domain
              copy_data_into_domain(inputs, task_domain)

              # write the task
              write(task)

              # put task schedule process log
              task_process_record = Log::TaskProcessRecord.new.tap do |record|
                record.name = task.digest
                record.rule_name = rule.rule_path
                record.rule_type = rule.rule_type
                record.inputs = inputs.flatten.map{|input| input.name}.join(",")
                record.parameters = callee.expr.params.textize
                record.transition = "schedule"
              end
              process_log(task_process_record)

              msg = "distributed task %s on %s" % [task.digest, handler_digest]
              user_message(msg, 1)

              next
            end
          rescue Rinda::RedundantTupleError
            # ignore
          end

          show "cancel task %s on %s" % [task.digest, handler_digest]
          canceled << task_domain
        end

        # wait to finish threads
        applications.uniq.each do |callee, rule, inputs, vtable|
          # task domain
          task_domain = ID.domain_id3(rule, inputs, callee)

          # wait to finish the work
          template = Tuple[:finished].new(
            domain: task_domain,
            status: :succeeded
          )
          finished = read(template)

          unless canceled.include?(task_domain)
            msg = "finished task %s on %s" % [finished.domain, handler_digest]
            user_message(msg, 1)
          end

          # copy data from task domain to this domain
          @finished << finished
          copy_data_into_domain(finished.outputs, @domain)

          # output ticket
          callee.expr.output_ticket_expr.names.each do |name|
            write(Tuple[:ticket].new(@domain, name))
          end
        end

        process_log(@rule_process_record.merge(transition: "resume"))
        process_log(@task_process_record.merge(transition: "resume"))
        user_message_end("End Task Distribution: %s" % handler_digest)
      end

      # Return true if we need to write the task into the tuple space.
      #
      # @param [TaskTuple] task
      #   task tuple
      # @return [Boolean]
      #   true if we need to write the task into the tuple space
      def need_to_process_task?(task)
        not(read!(task) or working?(task))
      end

      # Return true if any task worker is working on the task.
      #
      # @param task [TaskTuple]
      #   task tuple
      # @return [Boolean]
      #   true if any task worker is working on the task
      def working?(task)
        read!(Tuple[:working].new(domain: task.domain))
      end

      # Find outputs from the domain.
      #
      # @return [void]
      def find_outputs
        tuples = read_all(Tuple[:data].new(domain: @domain))
        @rule.outputs.each_with_index do |output, i|
          output = output.eval(@variable_table)
          case output.modifier
          when :all
            @outputs[i] = tuples.find_all {|data| output.match(data.name)}
          when :each
            # FIXME
            @outputs[i] = tuples.find {|data| output.match(data.name)}
          end
        end
      end

      # Lift output data from child domains to this domain.
      #
      # @return [void]
      def lift_output_data
        @outputs.flatten.compact.inject([]) do |lifted, output|
          old_location = output.location
          new_location = make_output_location(output.name)
          unless new_location == old_location or lifted.include?(old_location)
            # move data from old to new
            old_location.move(new_location)
            # sync cache if the old is cached in this machine
            FileCache.sync(old_location, new_location)
            # write lift tuple
            write(Tuple[:lift].new(old_location, new_location))
            # push history
            lifted << old_location
          end
          lifted
        end
      end

      # Validate outputs size.
      def validate_outputs
        # size check
        if @rule.outputs.size > 0 and not(@rule.outputs.size == @outputs.size)
          raise RuleExecutionError.new(self)
        end

        # nil check
        if @outputs.any?{|tuple| tuple.nil?}
          raise RuleExecutionError.new(self)
        end

        # empty list check
        @outputs.each_with_index do |tuple, i|
          output = @rule.outputs[i].eval(@variable_table)
          if tuple.kind_of?(Array) && tuple.empty? && not(output.accept_nonexistence?)
            raise RuleExecutionError.new(@outputs.inspect)
          end
        end
      end

      # Import finished tuple's outputs from the domain.
      #
      # @param [String] task_domain
      #   target task domain
      # @return [void]
      def import_finished_outputs(task_domain)
        return if @finished.any?{|t| t.domain == task_domain}
        if task_domain != @domain
          template = Tuple[:finished].new(
            domain: task_domain,
            status: :succeeded
          )
          if finished = read!(template)
            copy_data_into_domain(finished.outputs, @domain)
          end
        end
      end

      # Copy data into specified domain and return the tuple list
      def copy_data_into_domain(src_data, dest_domain)
        src_data.flatten.compact.map do |d|
          new_data = d.clone
          new_data.domain = dest_domain
          begin
            write(new_data)
          rescue Rinda::RedundantTupleError
            # ignore
          end
          new_data
        end
      end
    end
  end
end
