module Pione
  module RuleHandler
    # FlowHandler represents a handler for flow actions.
    class FlowHandler < BaseHandler
      # :nodoc:
      def initialize(*args)
        super
        @data_finder = DataFinder.new(tuple_space_server, @domain)
        @finished = []
      end

      # Process flow elements.
      def execute
        user_message ">>> Start Flow Rule #{@rule.rule_path}"

        # rule application
        apply_rules(@rule.body.eval(@variable_table).elements)
        # find outputs
        find_outputs
        # check output validation
        validate_outputs

        debug_message "Flow Rule #{@rule.rule_path} Result: #{@outputs}"
        user_message ">>> End Flow Rule #{@rule.rule_path}"

        return @outputs
      end

      # Return true if the handler is waiting finished tuple.
      def finished_waiting?
        # FIXME
        false
      end

      private

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
            break # finish applications
          end
        end

        user_message ">>> End Rule Application: #{@rule.rule_path}"
      end

      # Find applicable flow-element rules with inputs and variables.
      def find_applicable_rules(callers)
        callers.inject([]) do |combinations, caller|
          caller = caller.eval(@variable_table)
          vtable = caller.expr.params.eval(@variable_table).as_variable_table
          # find element rule
          rule = find_rule(caller).eval(vtable)
          # check rule status and find combinations
          @data_finder.find(:input, rule.inputs, vtable).each do |res|
            combinations << [caller, rule, res.combination, res.variable_table]
          end
          # find next
          combinations
        end
      end

      # Find the rule for the caller.
      def find_rule(caller)
        begin
          caller = caller.eval(@variable_table)
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
        combinations.select do |caller, rule, inputs, vtable|
          # task domain
          task_domain = Util.domain(
            rule.expr.package.name,
            rule.expr.name,
            inputs,
            caller.expr.params
          )
          begin
            # import finished tuples's data
            unless @finished.find{|f| f.domain == task_domain}
              if task_domain != @domain
                finished = read(
                  Tuple[:finished].new(
                    domain: task_domain,
                    status: :succeeded
                  ),
                  0
                )
                copy_data_into_domain(finished.outputs, @domain)
              end
            end
          rescue Rinda::RequestExpiredError
          end
          outputs_combination = @data_finder.find(
            :output,
            rule.outputs.map{|output| output.eval(vtable)},
            vtable
          ).map{|r| r.combination }
          # no combinations is empty list
          outputs_combination = [[]] if outputs_combination.empty?
          # check update criterias
          outputs_combination.any?{|outputs|
            UpdateCriteria.satisfy?(rule, inputs, outputs, vtable)
          }
        end
      end

      def distribute_tasks(applications)
        user_message ">>> Start Task Distribution: #{@rule.rule_path}"

        # FIXME: rewrite by using fiber
        thgroup = ThreadGroup.new

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
              @finished << finished
              copy_data_into_domain(finished.outputs, @domain)
            end
          end

          thgroup.add(thread)
        end

        # wait to finish threads
        thgroup.list.each {|th| th.join}

        user_message ">>> End Task Distribution: #{@rule.rule_path}"
      end

      # Find outputs from the domain of tuple space.
      def find_outputs
        @rule.outputs.each_with_index do |output, i|
          output = output.eval(@variable_table)
          list = read_all(Tuple[:data].new(domain: @domain))
          case output.modifier
          when :all
            @outputs[i] = list.select {|data| output.match(data.name)}
          when :each
            @outputs[i] = list.find {|data| output.match(data.name)}
          end
        end
      end

      # Validates outputs size.
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
        if @outputs.any?{|tuple| tuple.kind_of?(Array) && tuple.empty?}
          raise RuleExecutionError.new(self)
        end
      end

      # Copy data into specified domain and return the tuple list
      def copy_data_into_domain(src_data, dist_domain)
        src_data.flatten.map do |d|
          new_data = d.clone
          new_data.domain = dist_domain
          write(new_data)
          new_data
        end
      end
    end
  end
end
