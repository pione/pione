module Pione
  module Agent
    class ProcessManager < TupleSpaceClient
      set_agent_type :process_manager, self

      #
      # instance method
      #

      attr_reader :package

      def initialize(space, env, package, param_sets, stream)
        raise ArgumentError unless env.rule_get!(RuleExpr.new("Main"))
        super(space)
        @space = space
        @env = env
        @package = package
        @param_sets = param_sets
        @stream = stream
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
        # setup root rule
        definition = @env.make_root_rule(@param_sets)
        @rule_condition = definition.rule_condition_context.eval(@env)

        # share my environment
        write(Tuple[:env].new(@env.dumpable)) # need to be dumpable
      end

      def transit_to_sleep
        take(Tuple[:command].new("start-root-rule", nil))
      end

      def transit_to_run
        finder = RuleEngine::DataFinder.new(@space, 'root')
        list = Enumerator.new(finder, :find, :input, @rule_condition.inputs, @env).to_a
        if list.empty?
          user_message "error: no inputs"
          terminate
        else
          list.each do |env, inputs|
            handler = RuleEngine.make(@space, @env, @env.current_package_id, "Root", inputs, ParameterSet.new, 'root', nil)
            handler.handle
          end
        end

        return
      end

      def transit_to_terminate
        Global.front.terminate
      end
    end
  end
end
