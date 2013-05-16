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

        # check input tickets
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

          # callee parameters inherit caller parameters
          @variable_table.variables.each do |var|
            val = @variable_table.get(var)
            if val.kind_of?(Callable) or val.kind_of?(Variable) or val.void?
              if rule.params.keys.include?(var)
                callee.expr.params.set_safety!(var, val)
              end
            end
          end

          # build callee parameter from rule definition
          callee_params = rule.params.merge(callee.expr.params)

          # expand parameters
          callee_params.eval(@variable_table).each do |atomic_params|

            # eval callee rule by the context
            vtable = atomic_params.eval(@variable_table).as_variable_table
            rule = rule.eval(vtable)

            # check rule status and find combinations
            @data_finder.find(:input, rule.inputs, vtable).each do |res|
              combinations << [
                callee,
                atomic_params,
                rule,
                res.combination,
                res.variable_table,
                ID.domain_id3(rule, res.combination, atomic_params)
              ] if rule.constraints.satisfy?(res.variable_table)
            end
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
        combinations.map do |callee, params, rule, inputs, vtable, task_domain|
          # find outputs combination
          outputs_combination = @data_finder.find(
            :output,
            rule.outputs.map{|output| output.eval(vtable)},
            vtable
          ).map{|r| r.combination }

          # no outputs combination means empty list
          outputs_combination = [[]] if outputs_combination.empty?

          # read all data null
          data_null_tuples = read_all(Tuple::DataNullTuple.new(domain: task_domain))

          # check update criterias
          orders = outputs_combination.map {|outputs|
            UpdateCriteria.order(rule, inputs, outputs, vtable, data_null_tuples)
          }
          order = nil
          order = :weak if orders.include?(:weak)
          order = :force if orders.include?(:force)
          [callee, params, rule, inputs, vtable, task_domain, order]
        end.select {|_, _, _, _, _, _, order| not(order.nil?)}
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

        applications.uniq.each do |callee, params, rule, inputs, vtable, task_domain, order|
          # make a task tuple
          task = Tuple[:task].new(
            rule.rule_path,
            inputs,
            params,
            rule.features,
            task_domain,
            @call_stack + [@domain] # current call stack + caller
          )

          # check if the same task exists or finished already
          if need_to_process_task?(task, order)
            # clear finished tuple
            remove_finished_tuple(task.domain)

            # copy input data from this domain to the task domain
            inputs.flatten.each {|input| copy_data_into_domain(input, task_domain)}

            # write the task
            write(task)

            # put task schedule process log
            task_process_record = Log::TaskProcessRecord.new.tap do |record|
              record.name = task.digest
              record.rule_name = rule.rule_path
              record.rule_type = rule.rule_type
              record.inputs = inputs.flatten.map{|input| input.name}.join(",")
              record.parameters = params.textize
              record.transition = "schedule"
            end
            process_log(task_process_record)

            # message
            msg = "distributed task %s on %s" % [task.digest, handler_digest]
            user_message(msg, 1)
          else
            # cancel the task
            show "cancel task %s on %s" % [task.digest, handler_digest]
            canceled << task_domain
          end
        end

        # wait to finish threads
        applications.uniq.each do |callee, params, rule, inputs, vtable, task_domain, order|
          # wait to finish the work
          template = Tuple[:finished].new(
            domain: task_domain,
            status: :succeeded
          )
          finished = read(template)

          # show message about canceled tasks
          unless canceled.include?(task_domain)
            msg = "finished task %s on %s" % [finished.domain, handler_digest]
            user_message(msg, 1)
          end

          # copy write operation data tuple from the task domain to this domain
          update_by_finished_tuple(rule, finished, vtable)

          # publish tickets into the domain
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
      # @param task [TaskTuple]
      #   task tuple
      # @param order [Symbol]
      #   update order type
      # @return [Boolean]
      #   true if we need to write the task into the tuple space
      def need_to_process_task?(task, order)
        # reuse task finished result if order is weak update
        if order == :weak
          if read!(Tuple[:finished].new(domain: task.domain, status: :succeeded))
            return false
          end
        end
        # check task status
        not(read!(task) or read!(Tuple[:working].new(domain: task.domain)))
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

        # empty list or nil check
        @outputs.each_with_index do |tuple, i|
          output = @rule.outputs[i].eval(@variable_table)
          unless output.accept_nonexistence?
            if tuple.nil? or (tuple.kind_of?(Array) && tuple.empty?)
              raise RuleExecutionError.new(self)
            end
          end
        end
      end

      # Remove finished tuple.
      #
      # @param domain [String]
      #   domain of the finished tuple
      # @return [void]
      def remove_finished_tuple(domain)
        take!(Tuple[:finished].new(domain: domain))
      end

      # Import finished tuple's outputs from the domain.
      #
      # @param [String] task_domain
      #   target task domain
      # @return [void]
      def update_by_finished_tuple(rule, finished, vtable)
        finished.outputs.each_with_index do |output, i|
          data_expr = rule.outputs[i].eval(vtable)
          case data_expr.operation
          when :write
            if output.kind_of?(Array)
              output.each {|o| copy_data_into_domain(o, @domain)}
            else
              copy_data_into_domain(output, @domain)
            end
          when :remove
            if output.kind_of?(Array)
              output.each {|o| remove_data_from_domain(o, @domain)}
            else
              remove_data_from_domain(output, @domain)
            end
          when :touch
            if output.kind_of?(Array)
              output.each {|o| touch_data_in_domain(o, @domain)}
            else
              touch_data_in_domain(output, @domain)
            end
          end
        end
      end

      # Copy the data tuple with the specified domain and return the tuple list.
      #
      # @param data [DataTuple]
      #   target data tuple
      # @param domain [String]
      #   new domain of the copied data tuple
      # @return [DataTuple]
      #   new data tuple with the domain or nil
      def copy_data_into_domain(data, domain)
        return nil unless data
        new_data = data.clone.tap {|x| x.domain = domain}
        write(new_data)
        return new_data
      end

      # Remove the data from the domain.
      def remove_data_from_domain(data, domain)
        take!(Tuple[:data].new(name: data.name, domain: domain))
      end

      def touch_data_in_domain(data, domain)
        if target = read!(Tuple[:data].new(name: data.name, domain: domain))
          data = target
        end
        new_data = data.clone.tap {|x| x.domain = domain; x.time = Time.now}
        write(new_data)
      end
    end
  end
end
