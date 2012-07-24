module Pione
  module RuleHandler
    # FlowHandler represents a handler for flow actions.
    class FlowHandler < BaseHandler
      # :nodoc:
      def initialize(*args)
        super
        @data_finder = DataFinder.new(tuple_space_server, @domain)
      end

      # Process flow elements.
      def execute
        user_message ">>> Start Flow Rule #{@rule.rule_path}"

        # rule application
        apply_rules(@rule.body.eval(@variable_table).elements)

        # find outputs
        find_outputs

        # check output validation
        if @rule.outputs.size > 0 and not(@rule.outputs.size == @outputs.size)
          raise RuleExecutionError.new(self)
        end

        if debug_mode?
          debug_message "Flow Rule #{@rule.rule_path} Result:"
          @outputs.each {|output| debug_message "  #{output}"}
        end

        user_message ">>> End Flow Rule #{@rule.rule_path}"

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
        @rule.outputs.each_with_index do |expr, i|
          expr = expr.eval(@variable_table)
          list = read_all(Tuple[:data].new(domain: @domain))
          if expr.all?
            # case all modifier
            names = list.select {|elt| exp.match(elt.name)}
            unless names.empty?
              @outputs[i] = names
            end
          else
            # case each modifier
            name = list.find {|elt| expr.match(elt.name)}
            if name
              @outputs[i] = name
            end
          end
        end
      end

      # Apply target input data to rules.
      def apply_rules(callers)
        user_message ">>> Start Rule Application: #{@rule.rule_path}"

        # apply flow-element rules
        while true do
          # find updatable rule applications
          applications = select_updatables(find_applicable_rules(callers))

          unless applications.empty?
            # push task tuples into tuple space
            distribute_tasks(applications)
          else
            # finish applications
            break
          end
        end

        user_message ">>> End Rule Application: #{@rule.rule_path}"
      end

      # Find applicable flow-element rules with inputs and variables.
      def find_applicable_rules(callers)
        combinations = []
        callers.each do |caller|
          # find element rule
          rule = find_rule(caller)
          # check rule status and find combinations
          @data_finder.find(:input, rule.inputs).each do |res|
            combinations << [caller, rule, res.combination, res.variable_table]
          end
        end
        return combinations
      end

      # Find the rule for the caller.
      def find_rule(caller)
        begin
          return read(Tuple[:rule].new(rule_path: caller.rule_path), 0).content
        rescue Rinda::RequestExpiredError
          debug_message "Request loading a rule #{caller.rule_path}"
          write(Tuple[:request_rule].new(caller.rule_path))
          tuple = read(Tuple[:rule].new(rule_path: caller.rule_path))

          # check whether known or unknown
          if tuple.status == :known
            return tuple.content
          else
            raise UnknownRule.new(caller.rule_path)
          end
        end
      end

      # Find inputs and variables for flow element rules.
      def select_updatables(combinations)
        combinations.select do |caller, rule, inputs, variable_table|
          outputs = @data_finder.find(:output, rule.outputs, variable_table).map{|r| r.combination }
          UpdateCriteria.satisfy?(rule, inputs, outputs)
        end
      end

      def distribute_tasks(applications)
        # FIXME: rewrite by using fiber
        thgroup = ThreadGroup.new

        user_message ">>> Start Task Distribution: #{@rule.rule_path}"

        applications.each do |caller, rule, inputs, variable_table|
          thread = Thread.new do
            # task domain
            task_domain = Util.domain(
              rule.expr.package.name,
              rule.expr.name,
              inputs,
              caller.expr.params
            )

            # copy input data from the handler domain to task domain
            copy_data_into_domain(inputs, task_domain)

            # make a task tuple and write it
            task = Tuple[:task].new(
              rule.rule_path,
              inputs,
              caller.expr.params,
              rule.features,
              Util.uuid
            )
            write(task)

            # wait to finish the work
            finished = read(Tuple[:finished].new(domain: task_domain))
            user_message "task finished: #{finished}"

            # copy data from task domain to this domain
            if finished.status == :succeeded
              # copy output data from task domain to the handler domain
              copy_data_into_domain(finished.outputs, @domain)
            end
          end

          thgroup.add(thread)
        end

        # wait to finish threads
        thgroup.list.each {|th| th.join}

        user_message ">>> End Task Distribution: #{@rule.rule_path}"
      end

      def finalize_rule_application(sync_monitor)
        # stop sync monitor
        sync_monitor.terminate
      end

      # Copy data into specified domain
      def copy_data_into_domain(orig_data, new_domain)
        orig_data.flatten.each do |d|
          new_data = d.clone
          new_data.domain = new_domain
          write(new_data)
        end
      end
    end
  end
end
