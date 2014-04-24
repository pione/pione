module Pione
  module Agent
    class JobManager < TupleSpaceClient
      include Log::MessageLog
      set_agent_type :job_manager, self

      #
      # instance method
      #

      attr_reader :package

      def initialize(tuple_space, env, package, param_set, stream)
        unless env.rule_get!(Lang::RuleExpr.new("Main"))
          raise JobError.new("Rule `Main` not found in the package.")
        end

        super(tuple_space)
        @tuple_space = tuple_space
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

        # collect tuple space attributes
        @request_from = @tuple_space.attribute("request_from")
        @session_id = @tuple_space.attribute("session_id")
        @client_ui = @tuple_space.attribute("client_ui")
      end

      def transit_to_sleep
        take(TupleSpace::CommandTuple.new("start-root-rule", nil))
      end

      def transit_to_run
        finder = RuleEngine::DataFinder.new(@tuple_space, 'root')
        list = Enumerator.new(finder, :find, :input, @rule_condition.inputs, @env).to_a
        if list.empty?
          user_message "error: no inputs"
          terminate
        else
          # call root rule of the current package
          list.each do |env, inputs|
            engine_param = {
              :tuple_space  => @tuple_space,
              :env          => @env,
              :package_id   => @env.current_package_id,
              :rule_name    => "Root",
              :inputs       => inputs,
              :param_set    => Lang::ParameterSet.new,
              :domain_id    => 'root',
              :caller_id    => nil,
              :request_from => @request_from,
              :session_id   => @session_id,
              :client_ui    => @client_ui
            }
            RuleEngine.make(engine_param).handle
          end
        end

        # terminate if the agent is not stream mode
        terminate unless @stream

        return
      end
    end
  end
end
