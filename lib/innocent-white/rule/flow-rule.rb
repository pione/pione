require 'innocent-white/common'
require 'innocent-white/update-criteria'

module InnocentWhite
  module Rule

    # FlowRule represents a flow structured rule. This rule is consisted by flow
    # elements and executes elements actions.
    class FlowRule < BaseRule
      # Return false because flow rule is not action rule.
      def action?
        false
      end

      # Return true.
      def flow?
        true
      end
    end

    # FlowHandler represents a handler for a flow action.
    class FlowHandler < BaseHandler
      def execute
        user_message ">>> Start Flow Rule #{@rule.path}"

        # 1. apply flow elements
        apply_rules

        # 2. find outputs
        find_outputs

        # 3. check output
        if @rule.outputs.size > 0 and not(@rule.outputs.size == @outputs.size)
          raise ExecutionError.new(self)
        end

        if debug_mode?
          puts "Flow Rule #{@rule.path} Result:"
          @outputs.each {|output| puts "  #{output}"}
        end

        user_message ">>> End Flow Rule #{@rule.path}"

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

      # Apply target input data to rules.
      def apply_rules
        user_message ">>> Start Rule Application: #{@rule.path}"

        # SyncMonitor
        sync_monitor = Agent[:sync_monitor].start(tuple_space_server, self)

        while true do
          # find applicable input combinations
          inputs = find_applicable_input_combinations

          # find update targets which satisfies update criteria
          update_targets = find_updatable_targets(inputs)

          unless update_targets.empty?
            # distribute task
            handle_task(update_targets)
          else
            # finish application
            break
          end
        end

        # release lock of sync monitor
        sync_monitor.sync
        sync_monitor.terminate

        user_message ">>> End Rule Application: #{@rule.path}"
      end

      # Check application inputs.
      def find_applicable_input_combinations
        inputs = []
        @content.each do |caller|
          # find element rule
          rule = find_rule(caller)
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

      # Find the rule for the caller.
      def find_rule(caller)
        begin
          return read(Tuple[:rule].new(rule_path: caller.rule_path), 0)
        rescue Rinda::RequestExpiredError
          puts "Request loading a rule #{caller.rule_path}" if debug_mode?
          write(Tuple[:request_rule].new(caller.rule_path))
          return read(Tuple[:rule].new(rule_path: caller.rule_path))
        end
      end

      # Find input combinations and variables for element rules.
      def find_updatable_targets(inputs)
        targets = []
        inputs.each do |rule, combinations|
          combinations.each do |inputs, var|
            outputs = rule.content.find_outputs(tuple_space_server, @domain, inputs, var)
            if UpdateCriteria.satisfy?(inputs, outputs)
              targets << [rule, inputs, var]
            end
          end
        end
        return targets
      end

      def handle_task(targets)
        # FIXME: rewrite by using fiber
        thgroup = ThreadGroup.new

        user_message ">>> Start Task Distribution: #{@rule.path}"

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

        user_message ">>> End Task Distribution: #{@rule.path}"
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
  end
end
