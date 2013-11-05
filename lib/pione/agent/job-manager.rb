module Pione
  module Agent
    class JobManager < TupleSpaceClient
      include Log::MessageLog
      set_agent_type :job_manager, self

      #
      # instance method
      #

      attr_reader :package

      def initialize(space, env, package, param_set, stream)
        unless env.rule_get!(Lang::RuleExpr.new("Main"))
          raise JobError.new("Rule `Main` not found in the package.")
        end

        super(space)
        @space = space
        @env = env
        @package = package
        @param_set = param_set
        @stream = stream
        @package_id = @env.current_package_id
      end

      #
      # agent activities
      #

      define_transition :run
      define_transition :sleep

      chain :init => :sleep
      chain :sleep => :run
      chain :run => lambda {|agent| @stream ? :sleep : :terminate}

      #
      # transitions
      #

      def transit_to_init
        # split parameter set as package toplvel's and main's
        toplevel_variable_names = @env.variable_table.select_names_by(@env, @env.current_package_id)
        toplevel_param_set = @param_set.filter(toplevel_variable_names)
        main_param_set = @param_set.delete_all(toplevel_variable_names)

        # merge the toplevel parameter set
        @env.merge_param_set(toplevel_param_set, force: true)

        # setup root rule
        root_definition = @env.make_root_rule(main_param_set)
        @rule_condition = root_definition.rule_condition_context.eval(@env)

        # share my environment
        write(TupleSpace::EnvTuple.new(@env.dumpable)) # need to be dumpable
      end

      def transit_to_sleep
        take(TupleSpace::CommandTuple.new("start-root-rule", nil))
      end

      def transit_to_run
        finder = RuleEngine::DataFinder.new(@space, 'root')
        list = Enumerator.new(finder, :find, :input, @rule_condition.inputs, @env).to_a
        if list.empty?
          user_message "error: no inputs"
          terminate
        else
          # call root rule of the current package
          list.each do |env, inputs|
            package_id = @env.current_package_id
            handler = RuleEngine.make(@space, @env, package_id, "Root", inputs, Lang::ParameterSet.new, 'root', nil)
            handler.handle
          end
        end

        return
      end
    end
  end
end
