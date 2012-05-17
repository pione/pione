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

      # Return FlowHandler class.
      def handler_class
        FlowHandler
      end
    end

    # FlowHandler represents a handler for flow actions.
    class FlowHandler < BaseHandler
      # :nodoc:
      def initialize(*args)
        super
        @data_finder = DataFinder.new(tuple_space_server, @domain)
      end

      # :nodoc:
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
          debug_message "Flow Rule #{@rule.path} Result:"
          @outputs.each {|output| debug_message "  #{output}"}
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
          exp = exp.with_variable_table(@variable_table)
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

        # apply flow-element rules
        while true do
          # find updatable rule applications
          applications = select_updatables(find_applicable_rules)

          unless applications.empty?
            distribute_tasks(applications)
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

      # Find applicable flow-element rules with inputs and variables.
      def find_applicable_rules
        combinations = []
        @content.each do |caller|
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
            task_domain = Util.domain(rule.rule_path, inputs, [])

            # sync monitor
            # if caller.sync_mode?
            #   name = variable_table.expand(rule.rule_path)
            #   tuple = Tuple[:sync_target].new(src: task_domain,
            #                                   dest: @domain,
            #                                   name: name)
            #   write(tuple)
            # end

            # copy input data from the handler domain to task domain
            copy_data_into_domain(inputs, task_domain)

            # FIXME: params is not supportted now
            task = Tuple[:task].new(rule.rule_path,
                                    inputs,
                                    [],
                                    rule.features,
                                    Util.uuid)
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
