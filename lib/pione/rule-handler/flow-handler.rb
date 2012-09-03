module Pione
  module RuleHandler
    # FlowHandler represents a handler for flow actions.
    class FlowHandler < BaseHandler
      def self.message_name
        "Flow"
      end

      # :nodoc:
      def initialize(*args)
        super
        @data_finder = DataFinder.new(tuple_space_server, @domain)
        @finished = []
      end

      # Starts to process flow elements.
      def execute
        # rule application
        apply_rules(@rule.body.eval(@variable_table).elements)
        # find outputs
        find_outputs
        # check output validation
        validate_outputs


        return @outputs
      end

      # Return true if the handler is waiting finished tuple.
      def finished_waiting?
        # FIXME
        false
      end

      private

      # Returns digest string of the task.
      def task_digest(task)
        "%s([%s],[%s])" % [
          task.rule_path,
          task.inputs.map{|i|
            i.kind_of?(Array) ? "[%s, ...]" % i[0].name : i.name
          }.join(","),
          task.params.data.map{|k,v| "%s:%s" % [k.name, v.textize]}.join(",")
        ]
      end

      # Apply target input data to rules.
      def apply_rules(callees)
        user_message_begin("Start Rule Application: %s" % handler_digest)

        # apply flow-element rules
        while true do
          # find updatable rule applications
          applications = select_updatables(find_applicable_rules(callees))

          unless applications.empty?
            # push task tuples into tuple space
            distribute_tasks(applications)
          else
            break # finish applications
          end
        end

        user_message_end("End Rule Application: %s" % handler_digest)
      end

      # Find applicable flow-element rules with inputs and variables.
      def find_applicable_rules(callees)
        callees.inject([]) do |combinations, callee|
          # eval callee expr by handling rule context
          callee = callee.eval(@variable_table)

          # find callee rule
          rule = find_callee_rule(callee)

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

      # Find the rule of the callee.
      def find_callee_rule(callee)
        begin
          return read(Tuple[:rule].new(rule_path: callee.rule_path), 0).content
        rescue Rinda::RequestExpiredError
          debug_message "Request loading a rule #{callee.rule_path}"
          write(Tuple[:request_rule].new(callee.rule_path))
          tuple = read(Tuple[:rule].new(rule_path: callee.rule_path))

          # check whether known or unknown
          if tuple.status == :known
            return tuple.content
          else
            raise UnknownRule.new(callee.rule_path)
          end
        end
      end

      # Find inputs and variables for flow element rules.
      def select_updatables(combinations)
        combinations.select do |callee, rule, inputs, vtable|
          # task domain
          task_domain = Util.domain(
            rule.expr.package.name,
            rule.expr.name,
            inputs,
            callee.expr.params
          )
          # import finished tuples's data
          begin
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
          # no outputs combination means empty list
          outputs_combination = [[]] if outputs_combination.empty?
          # check update criterias
          outputs_combination.any?{|outputs|
            UpdateCriteria.satisfy?(rule, inputs, outputs, vtable)
          }
        end
      end

      def distribute_tasks(applications)
        # FIXME: rewrite by using fiber
        thgroup = ThreadGroup.new

        user_message_begin("Start Task Distribution: %s" % handler_digest)

        applications.uniq.each do |callee, rule, inputs, variable_table|

          thread = Thread.new do
            # task domain
            task_domain = Util.domain(
              rule.expr.package.name,
              rule.expr.name,
              inputs,
              callee.expr.params
            )

            # make a task tuple and write it
            task = Tuple[:task].new(
              rule.rule_path,
              inputs,
              callee.expr.params,
              rule.features,
              task_domain,
              @call_stack + [@domain]
            )

            # check if same task exists
            canceled = false
            if need_task?(task)
              # copy input data from the handler domain to task domain
              copy_data_into_domain(inputs, task_domain)

              # write the task
              write(task)

              user_message("distributed task %s on %s" % [task.digest, handler_digest], 1)
            else
              show "cancel task %s on %s" % [task.digest, handler_digest]
              canceled = true
            end

            # wait to finish the work
            finished = read(Tuple[:finished].new(domain: task_domain))
            unless canceled
              user_message("finished task %s on %s" % [
                  finished.domain, handler_digest
                ], 1)
            end

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

        user_message_end("End Task Distribution: %s" % handler_digest)
      end

      def need_task?(task)
        if exist_task?(task) or working?(task)
          return false
        else
          return true
        end
      end

      def exist_task?(task)
        begin
          read(task, 0)
          return true
        rescue Rinda::RequestExpiredError
          return false
        end
      end

      def working?(task)
        begin
          read(Tuple[:working].new(:domain => task.domain), 0)
          return true
        rescue Rinda::RequestExpiredError
          return false
        end
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
