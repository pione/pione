module Pione
  module Command
    # BasicCommand provides PIONE command model. PIONE commands have 4 phases:
    # "init", "setup", "action", "termination". Concrete commands implement some
    # processings as each phases.
    class BasicCommand
      class << self
        attr_reader :option_definition
        attr_reader :phase_option
        attr_reader :command_name_block
        attr_reader :command_front_block
        attr_reader :init_actions
        attr_reader :setup_actions
        attr_reader :execution_actions
        attr_reader :termination_actions
        attr_reader :exception_handler

        def inherited(subclass)
          subclass.instance_eval do
            @phase_option = {:init => {}, :setup => {}, :execution => {}, :termination => {}}
            @option_definition = OptionDefinition.new
            @command_name = nil
            @command_name_block = nil
            @command_banner = nil
            @command_front = nil
            @command_front_block = nil
            @init_actions = Array.new
            @setup_actions = Array.new
            @execution_actions = Array.new
            @termination_actions = Array.new
            @exception_handler = {:init => {}, :setup => {}, :execution => {}, :termination => {}}

            # define init phase actions
            init :process_name
            init :signal_trap
            init :option
            init :front
            init :process_additional_information
          end
        end

        # Set progaram name or return the name.
        def command_name(name=nil, &b)
          if name
            @command_name = name
            @command_name_block = block_given? ? b : nil
          else
            @command_name
          end
        end

        # Set program banner or return the banner.
        def command_banner(banner=nil)
          if banner
            @command_banner = banner
          else
            @command_banner
          end
        end

        # Set command front or return the front class.
        def command_front(front_class=nil, &b)
          if front_class
            @command_front = front_class
            @command_front_block = b
          else
            @command_front
          end
        end

        forward :@option_definition, :use, :use_option
        forward :@option_definition, :define, :define_option
        forward :@option_definition, :item, :option_item
        forward :@option_definition, :default, :option_default
        forward :@option_definition, :validate, :validate_option

        # Run the command with the arguments.
        def run(argv)
          self.new(argv).run
        end

        # Set setup phase options.
        def init_phase(option)
          set_phase_option(:init, option)
        end

        # Set setup phase options.
        def setup_phase(option)
          set_phase_option(:setup, option)
        end

        # Set execution phase options.
        def execution_phase(option)
          set_phase_option(:execution, option)
        end

        # Set termination phase options.
        def termination_phase(option)
          set_phase_option(:termination, option)
        end

        # Register the action to init phase.
        def init(action, option={})
          register_action(@init_actions, action, option)
        end

        # Register the action to setup phase.
        def setup(action, option={})
          register_action(@setup_actions, action, option)
        end

        # Register the action to execution phase.
        def execute(action, option={})
          register_action(@execution_actions, action, option)
        end

        # Register the action to termination phase.
        def terminate(action, option={})
          register_action(@termination_actions, action, option)
        end

        def handle_exception(phase_name, exceptions, &action)
          exceptions.each {|e| @exception_handler[phase_name][e] = action}
        end

        def handle_setup_exception(*exceptions, &action)
          handle_exception(:setup, exceptions, &action)
        end

        def handle_execution_exception(*exceptions, &action)
          handle_exception(:execution, exceptions, &action)
        end

        def handle_termination_exception(*exceptions, &action)
          handle_exception(:termination, exceptions, &action)
        end

        private

        # Set phase option.
        def set_phase_option(name, option)
          @phase_option[name] = option
        end

        # Register the action to the phase.
        def register_action(phase_actions, action, option={})
          _action = action.is_a?(Hash) ? action : {[] => action}
          _action.each do |key, val|
            phase_actions << [key.is_a?(Array) ? key : [key], val, option]
          end
        end
      end

      attr_reader :option
      attr_reader :running_thread

      forward! :class, :option_definition, :command_name, :command_name_block
      forward! :class, :command_banner, :command_front, :command_front_block

      def initialize(argv)
        @argv = argv
        @option = {}
        @__exit_status__ = true
        @__phase_name__ = nil
        @__action_name__ = nil

        # process has just one command object
        Global.command = self
      end

      # Run 4 phase lifecycle of the command. This fires actions in each phase.
      def run
        @running_thread = Thread.current
        enter_phase(:init)
        enter_phase(:setup)
        enter_phase(:execution)
        terminate # => enter_phase(:termination) and exit
      end

      # Enter setup phase.
      def enter_phase(phase_name)
        # avoid double launch
        return if @__phase_name__ == phase_name

        # show debug message for entering phase
        Log::Debug.system("%s enters phase \"%s\"" % [command_name, phase_name])

        limit = self.class.phase_option[phase_name][:timeout]
        phase_keyword, actions = find_phase_actions(phase_name)
        timeout(limit) do
          @__phase_name__ = phase_name
          actions.each do |(targets, action_name, action_option)|
            # check current mode is target or not
            if not(targets.empty?) and not(targets.include?(option[:action_mode]))
              next
            end

            # show debug message for firing action
            Log::Debug.system("%s fires action \"%s\" in phase \"%s\"" % [command_name, action_name, phase_name])

            # fire action
            @__action_name__ = action_name
            full_action_name = ("%s_%s" % [phase_keyword, action_name]).to_sym
            if action_option[:module]
              # call action in command action module
              instance_eval(&action_option[:module].get(full_action_name))
            else
              # call action in self object
              method(full_action_name).call
            end
          end
        end
      rescue *self.class.exception_handler[phase_name].keys => e
        self.class.exception_handler[phase_name][e.class].call(self, e)
      rescue Timeout::Error
        args = [command_name, @__action_name__, @__phase_name__, limit]
        abort("%s timeouted at action \"%s\" in phase \"%s\". (%i sec)" % args)
      end

      # Terminate the command. Note that this enters in termination phase first,
      # and command exit.
      def terminate
        enter_phase(:termination)
        exit # end with status code
      end

      # Return true if it is in init phase.
      def init?
        @__phase_name__ == :init
      end

      # Return true if it is in setup phase.
      def setup?
        @__phase_name__ == :setup
      end

      # Return true if it is in execution phase.
      def execution?
        @__phase_name__ == :execution
      end

      # Return true if it is in termination phase.
      def termination?
        @__phase_name__ == :termination
      end

      # Exit running command and return status.
      def exit
        Log::Debug.system("%s exits with status \"%s\"" % [command_name, @__exit_status__])
        Global.system_logger.terminate
        Kernel.exit(Global.exit_status)
      end

      # Exit running command and return failure status. Note that this method
      # enters termination phase before it exits.
      def abort(msg_or_exception, pos=caller(1).first)
        # hide the message because some option errors are meaningless
        invisible = msg_or_exception.is_a?(HideableOptionError)

        # setup abortion message
        msg = msg_or_exception.is_a?(Exception) ? msg_or_exception.message : msg_or_exception

        # show the message
        if invisible
          Log::Debug.system(msg, pos)
        else
          Log::SystemLog.fatal(msg, pos)
        end

        # set exit status code
        Global.exit_status = false

        # go to termination phase
        terminate
      end

      private

      # Initialize process name.
      def init_process_name
        $PROGRAM_NAME = command_name
      end

      # Initialize signal trap actions.
      def init_signal_trap
        # explicit exit for signal INT (exit status code: failure)
        Signal.trap(:INT) do
          abort("%s is terminated by signal INT" % command_name)
        end

        # implicit abortion for signal TERM (exit status code: success)
        Signal.trap(:TERM) do
          Log::Debug.system("%s is terminated by signal TERM" % command_name)
          terminate
        end
      end

      # Initialize command options.
      def init_option
        @option = option_definition.parse(@argv, command_name, command_banner)
      rescue OptionParser::ParseError, OptionError => e
        abort(e)
      end

      # Initialize front server of this process if it needs.
      def init_front
        if command_front
          front_args = command_front_block ? command_front_block.call(self) : []
          Global.front = command_front.new(*front_args)
        end
      end

      # Modify process name to be with the additional informations.
      def init_process_additional_information
        if self.class.command_name_block
          $PROGRAM_NAME = "%s (%s)" % [command_name, command_name_block.call(self)]
        end
      end

      # Find phase actions by phase name.
      def find_phase_actions(phase_name)
        case phase_name
        when :init; [:init, self.class.init_actions]
        when :setup; [:setup, self.class.setup_actions]
        when :execution; [:execute, self.class.execution_actions]
        when :termination; [:terminate, self.class.termination_actions]
        end
      end
    end

    module CommandActionInterface
      class << self
        def extended(mod)
          mod.instance_variable_set(:@action, Hash.new)
        end
      end

      # Return the named action.
      def get(name)
        @action[name] || (raise ActionNotFound.new(self, name))
      end

      def define_action(name, &b)
        @action[name] = b
      end
    end

    module CommonCommandAction
      extend CommandActionInterface

      define_action(:terminate_child_process) do |cmd|
        if Global.front
          # send signal TERM to the child process
          Global.front.child.each do |pid, uri|
            Util.ignore_exception {Process.kill(:TERM, pid)}
          end

          # wait all children
          children = Process.waitall.map{|(pid, _)| pid}
          if not(children.empty?)
            Log::Debug.system("%s killed #%s" % [cmd.command_name, children.join(", ")])
          end
        end
      end

      define_action(:setup_parent_process_connection) do |cmd|
        cmd.option[:parent_front].add_child(Process.pid, Global.front.uri)
        ParentFrontWatchDog.new(self) # start to watch parent process
      end

      define_action(:terminate_parent_process_connection) do |cmd|
        # maybe parent process is dead in this timing
        Util.ignore_exception do
          cmd.option[:parent_front].remove_child(Process.pid)
        end
      end
    end

    class ParentFrontWatchDog
      def initialize(command)
        @command = command

        Thread.new do
          while true
            # PPID 1 means the parent process is dead
            if Process.ppid == 1 or Util.error?{command.option[:parent_front].ping}
              break @command.terminate
            end
            sleep 1
          end
        end
      end
    end
  end
end
