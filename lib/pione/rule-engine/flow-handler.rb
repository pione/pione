module Pione
  module RuleEngine
    # FlowHandler is a rule handler for flow elements.
    class FlowHandler < BasicHandler
      # Start to process flow elements.
      #
      # @return [void]
      def execute
        # restore data tuples from domain_location
        restore_data_tuples_from_domain_location

        # start rule application
        rule_set = @rule_definition.flow_context.eval(@env)
        RuleApplication.new(self).apply(rule_set.rules.pieces)

        # find outputs
        outputs = find_outputs_from_space

        # lift output data from child domains to this domain
        lift_output_data(outputs)

        # check output validation
        validate_outputs(outputs)

        return outputs
      end

      # Restore data tuples from the domain location. This reads files in the
      # location and write it as data tuples.
      def restore_data_tuples_from_domain_location
        if @domain_location.exist?
          @domain_location.file_entries.each do |file|
            # ignore dot files
            unless file.basename[0] == "."
              write(TupleSpace::DataTuple.new(@domain_id, file.basename, file, file.mtime))
            end
          end
        end
      end

      # Lift output data from this domains to parent domain.
      #
      # @return [void]
      def lift_output_data(outputs)
        # we cannot lift up if caller id is unknown
        # NOTE: this is the case that we process root rule
        return if @caller_id.nil?

        outputs.flatten.compact.inject([]) do |lifted, output|
          old_location = output.location
          new_location = make_output_location(output.name)
          unless new_location == old_location or lifted.include?(old_location)
            if old_location.exist?
              # move data from old to new
              old_location.move(new_location)
              # sync cache if the old is cached in this machine
              System::FileCache.sync(old_location, new_location)
              # write lift tuple
              write(TupleSpace::LiftTuple.new(old_location, new_location))
              # push history
              lifted << old_location
            end
          end
          lifted
        end
      end

      # Validate outputs.
      def validate_outputs(outputs)
        _outputs = outputs.flatten.compact
        @rule_condition.outputs.each do |condition|
          _condition = condition.eval(@env)
          c1 = _condition.accept_nonexistence?
          c2 = _outputs.any?{|output| _condition.match?(output.name)}
          unless c1 or c2
            raise InvalidOutputError.new(self, outputs)
          end
        end
      end

      # Remove finished tuple.
      #
      # @param domain [String]
      #   domain of the finished tuple
      # @return [void]
      def remove_finished_tuple(domain)
        take!(TupleSpace::FinishedTuple.new(domain: domain))
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
        take!(TupleSpace::DataTuple.new(name: data.name, domain: domain))
      end

      def touch_data_in_domain(data, domain)
        if target = read!(TupleSpace::DataTuple.new(name: data.name, domain: domain))
          data = target
        end
        new_data = data.clone.tap {|x| x.domain = domain; x.time = Time.now}
        write(new_data)
      end
    end

    class Task < StructX
      member :env             # execution enviornment of this application
      member :domain_id       # domain id
      member :rule            # rule expression
      member :rule_definition # definition of the task's rule
      member :rule_condition  # rule condition
      member :inputs          # inputs
      member :param_set       # task parameters
      member :order           # week or force

      # Make a task tuple from the application.
      def make_tuple(caller_id)
        features = rule_condition.features.inject(Lang::FeatureSequence.new) do |f, expr|
          f + f.eval(env)
        end
        TupleSpace::TaskTuple.new(
          digest,
          rule.package_id,
          rule.name,
          inputs,
          param_set,
          features,
          domain_id,
          caller_id
        )
      end

      # Return digest string of the task.
      def digest
        @__digest__ ||= Util::TaskDigest.generate(rule.package_id, rule.name, inputs, param_set)
      end

      # Return task process record of the task.
      def make_task_process_record
        Log::TaskProcessRecord.new.tap do |record|
          record.name = digest
          record.package_id = rule.package_id
          record.rule_name = rule.name
          record.rule_type = rule_definition.rule_type
          record.inputs = inputs.flatten.map{|input| input.name}.join(",")
          record.parameters = param_set.textize
        end
      end

      def inspect
        args = [self.class, rule.package_id, rule.name, inputs, param_set, order]
        "#<%s package_id=%s, name=%s, inputs=%s, param_set=%s, order=%s>" % args
      end
      alias :to_s :inspect
    end

    class RuleApplication < SimpleDelegator
      def initialize(handler)
        super(handler)
        @data_finder = DataFinder.new(tuple_space_server, domain_id)
        @finished = [] # finished tuple cache
      end

      # Apply input data to rules.
      def apply(rules)
        # start message
        user_message_begin("Rule Application: %s" % digest, 1)

        # with profile
        Util::Profiler.profile(Util::RuleApplicationProfileReport.new(digest)) do
          # rule application loop
          while tasks = find_tasks(rules) do
            distribute_tasks(tasks)
          end
        end

        # end message
        user_message_end("Rule Application: %s" % digest, 1)
      end

      # Find applicable and updatable rule applications.
      def find_tasks(rules)
        # select applicable rules
        applicable_rules = find_applicable_rules(rules)

        # make task
        tasks = make_tasks(applicable_rules)

        # be careful that returns nil when tasks are empty
        tasks.empty? ? nil : tasks
      end

      # Find applicable rules. The criterion of applicable rule is that the rule
      # satisfies ticket conditions or not.
      def find_applicable_rules(rules)
        # select rules which ticktes exist in this domain
        rules.select do |rule|
          rule.input_tickets.pieces.all? do |ticket|
            read!(TupleSpace::TicketTuple.new(domain_id, ticket.name))
          end
        end
      end

      # Make tasks from rules.
      def make_tasks(rules)
        rules.each_with_object([]) do |rule, tasks|
          # set handler's package id if rule's package id is implicit
          rule = rule.set(package_id: package_id) unless rule.package_id

          # get rule definition
          rule_definition = env.rule_get(rule)

          # handle parameter sequence
          pieces = rule.param_sets.pieces
          if not(pieces.empty?)
            pieces.each do |param_set|
              ### merge default parameter values ####
              # setup task's environment by parameter set
              _env = plain_env.layer.merge(param_set)
              _env.set(current_package_id: rule.package_id || env.current_package_id)

              # get task's condition
              rule_condition = rule_definition.rule_condition_context.eval(_env)

              # merge default values
              _param_set = param_set.merge_default_values(rule_condition)

              # handle parameter distribution
              _param_set.expand do |expanded_param_set|
                # rebuild environment by expanded param set
                _env = plain_env.layer.merge(expanded_param_set)
                _env.set(current_package_id: rule.package_id || env.current_package_id)

                # get task's condition
                rule_condition = rule_definition.rule_condition_context.eval(_env)

                tasks.concat find_tasks_by_rule_condition(_env, rule, rule_definition, rule_condition, expanded_param_set).uniq
              end
            end
          else
            _env = plain_env.layer
            # get task's condition
            rule_condition = rule_definition.rule_condition_context.eval(_env)
            this_tasks = find_tasks_by_rule_condition(
              _env, rule, rule_definition, rule_condition, Lang::ParameterSet.new
            ).uniq
            tasks.concat(this_tasks)
          end
        end
      end

      # Handle parameter distribution. Rule parameters with each modifier are
      # distributed tasks by each element.
      def find_tasks_by_rule_condition(env, rule, rule_definition, rule_condition, param_set)
        tasks = []

        # find input data combinations
        @data_finder.find(:input, rule_condition.inputs, env) do |task_env, inputs|
          # make parameter set for the task
          table = Hash.new

          if val_i = task_env.variable_get!(Lang::Variable.new("I"))
            table["INPUT"] = Lang::Variable.new(name: "I", package_id: rule.package_id)
            table["I"] = val_i
          end

          if val_star = task_env.variable_get!(Lang::Variable.new("*"))
            table["*"] = val_star
          end

          task_param_set = param_set.set(table: param_set.table.merge(table))

          # check constraint conditions
          next unless rule_condition.constraints.all? do |constraint|
            res = constraint.eval(task_env)
            if res.is_a?(Lang::BooleanSequence)
              res.value
            else
              raise Lang::StructuralError.new(Lang::BooleanSequence, constraint.pos)
            end
          end

          # make task
          domain_id = Util::DomainID.generate(rule.package_id, rule.name, inputs, task_param_set)
          task = Task.new(task_env, domain_id, rule, rule_definition, rule_condition, inputs, task_param_set)

          # check updatability
          if _task = check_updatability(task)
            tasks << _task
          end
        end

        return tasks
      end

      # Check updatability of the task and get update order.
      def check_updatability(task)
        # read all tuples of data-null
        data_null_tuples = read_all(TupleSpace::DataNullTuple.new(domain: task.domain_id))

        res = []

        f = lambda do |task_env, outputs|
          # make parameter set for the task
          table = Hash.new

          if val_i = task_env.variable_get!(Lang::Variable.new("O"))
            table["OUTPUT"] = Lang::Variable.new("O")
            table["O"] = val_i
          end

          task_param_set = task.param_set.set(table: task.param_set.table.merge(table))

          # check update criterias
          order = UpdateCriteria.order(task_env, task.rule_condition, task.inputs, outputs, data_null_tuples)
          res << [order, task_env, task_param_set]
        end

        # find output data combination
        @data_finder.find(:output, task.rule_condition.outputs, task.env, &f)
        f.call(task.env, []) if res.empty?

        # evaluate the result
        groups = res.group_by {|(order, _, _)| order}
        if f = groups[:force] or f = groups[:weak]
          order, env, param_set = f.first

          # setup output variables
          var_o = Lang::Variable.new("O")
          task.env.variable_set(Lang::Variable.new("OUTPUT"), var_o)
          kseq = find_output_variables(task, Lang::KeyedSequence.new)
          task.env.variable_set(var_o, kseq)
          param_set = param_set.set(table: param_set.table.merge({"O" => kseq}))

          return task.set(order: order, env: env, param_set: param_set)
        else
          return nil
        end
      end

      def find_output_variables(task, kseq)
        _kseq = kseq
        task.rule_condition.outputs.each_with_index do |condition, i|
          begin
            data = condition.eval(task.env)
            _kseq = _kseq.put(Lang::IntegerSequence.of(i+1), data)
          rescue Lang::UnboundError
            next
          end
        end
        return _kseq
      end

      # Distribute tasks.
      def distribute_tasks(tasks)
        # log and message
        process_log(make_task_process_record.merge(transition: "suspend"))
        process_log(make_rule_process_record.merge(transition: "suspend"))
        user_message_begin("Distribution: %s" % digest, 2)

        # distribute tasks
        tasks.each do |task|
          tuple = task.make_tuple(domain_id)

          # publish tasks
          if need_to_publish_task?(task, tuple)
            # clear finished tuple and data tuples from the domain
            take!(TupleSpace::FinishedTuple.new(domain: task.domain_id))
            take_all!(TupleSpace::DataTuple.new(domain: task.domain_id))

            # copy input data from this domain to the task domain
            task.inputs.flatten.each {|input| copy_data_into_domain(input, task.domain_id)}

            # write the task
            write(tuple)

            # log and message
            process_log(task.make_task_process_record.merge(transition: "schedule"))
            user_message(">>> %s".color(:yellow) % task.digest, 3, "", :blue)
          else
            # cancel the task
            Log::Debug.rule_engine "task %s canceled at %s" % [task.digest, digest]
          end
        end

        # wait an end of distributed tasks
        wait_task_completion(tasks)

        # turn foreground if the task is background
        unless read!(TupleSpace::ForegroundTuple.new(domain_id, digest))
          write(TupleSpace::ForegroundTuple.new(domain_id, digest))
        end

        # log and message
        process_log(make_rule_process_record.merge(transition: "resume"))
        process_log(make_task_process_record.merge(transition: "resume"))
        user_message_end("Distribution: %s" % digest, 2)
      end

      # Return true if we need to publish the task.
      def need_to_publish_task?(task, tuple)
        # reuse task finished result if order is weak update
        if task.order == :weak
          template = TupleSpace::FinishedTuple.new(domain: task.domain_id, status: :succeeded)
          if @finished.include?(template)
            return false
          end
          if finished = read!(template)
            @finished << finished
            return false
          end
        end

        # the task exists in space already, so we don't need to publish
        return false if read!(tuple)

        # another worker is working now, so we don't need to publish
        return false if read!(TupleSpace::WorkingTuple.new(domain: task.domain_id))

        # we need to publish the task
        return true
      end

      # Wait until tasks completed.
      def wait_task_completion(tasks)
        tasks.each do |task|
          # wait to finish the work
          finished = read(TupleSpace::FinishedTuple.new(domain: task.domain_id))

          ### task completion processing ###
          # copy write operation data tuple from the task domain to this domain
          import_outputs_of_task(task, finished)

          # touch tuple
          lift_touch_tuple(task)

          # publish output tickets
          task.rule.output_tickets.pieces.each do |piece|
            write(TupleSpace::TicketTuple.new(domain_id, piece.name))
          end
        end
      end

      # Import finished tuple's outputs from the domain.
      def import_outputs_of_task(task, finished)
        finished.outputs.each_with_index do |output, i|
          data_expr = task.rule_condition.outputs[i].eval(task.env)
          case data_expr.operation
          when :write
            if output.kind_of?(Array)
              output.each {|o| copy_data_into_domain(o, domain_id)}
            else
              copy_data_into_domain(output, domain_id)
            end
          when :remove
            if output.kind_of?(Array)
              output.each {|o| remove_data_from_domain(o, domain_id)}
            else
              remove_data_from_domain(output, domain_id)
            end
          when :touch
            if output.kind_of?(Array)
              output.each {|o| touch_data_in_domain(o, domain_id)}
            else
              touch_data_in_domain(output, domain_id)
            end
          end
        end
      end

      # Lift effects of touch operations from the task domain to this domain.
      def lift_touch_tuple(task)
        read_all(TupleSpace::TouchTuple.new(domain: task.domain_id)).each do |touch|
          if target = read!(TupleSpace::DataTuple.new(name: touch.name, domain: domain_id))
            # update time of data tuple
            write(target.tap {|x| x.time = touch.time}) unless target.time > touch.time

            # lift touch tuple to upper domain
            write(touch.tap{|x| x.domain = domain_id})
          end
        end
      end

    end
  end
end
