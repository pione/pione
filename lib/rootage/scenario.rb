module Rootage
  # ScenarioDefinition is an information table for Scenario class.
  class ScenarioDefinition
    # Create a new information table.
    def initialize(table=Hash.new)
      @table = table
      self[:name] ||= "anonymous"
    end

    # define forwarding messages
    forward :@table, :has_key?

    # Define a scenario information that associates key and value.
    #
    # @param key [Symbol]
    #   key name
    # @param val [Object]
    #   item's value
    # @param args_block [Proc]
    #   value's arguments
    # @return [void]
    def define(key, val=nil, &block)
      if val.nil? and not(block_given?)
        raise ArgumentError.new("Cannot define %{key} with no data." % {key: key})
      end
      @table[key] = {value: val, block: block}
    end

    # Return the item value of the key.
    #
    # @param key [Object]
    #   the key
    # @return [Object]
    #   the value
    def value_of(key)
      if @table.has_key?(key)
        @table[key][:value]
      end
    end
    alias :[] :value_of

    # Return the item block of the key.
    #
    # @param key [Object]
    #   the key
    # @return [Object]
    #   the block
    def block_of(key)
      if @table.has_key?(key)
        @table[key][:block]
      end
    end

    def []=(key, val)
      define(key, val)
    end

    def scenario_name
      self[:name]
    end

    def desc
      self[:desc]
    end

    def clone
      self.class.new(@table.clone)
    end
  end

  # ScenarioInterface provides basic methods for Scenario.
  module ScenarioInterface
    def define(*args)
      @info.define(*args)
    end

    def scenario_name
      @info.scenario_name
    end

    def desc
      @info.desc
    end

    # Return a process context class.
    #
    # @return [Class]
    #   process context class
    def process_context_class
      @info[:process_context_class]
    end

    # Return a phase class used for this scnario.
    def phase_class
      @info[:phase_class]
    end

    # Define a phase.
    #
    # @raise [ArgumentError]
    #   if there is same name phase already
    # @param name [String]
    #   phase name
    # @yieldparam phase [Phase]
    #   phase object
    # @return [void]
    def define_phase(name, &block)
      if @__phase__.has_key?(name)
        raise ArgumentError.new('Phase "%{name}" has been defined already.' % {name: name})
      end

      @__phase__[name] = phase_class.new(name)

      if block_given?
        block.call(@__phase__[name])
      end
    end

    # Find a phase object by the name.
    #
    # @param name [Symbol]
    #   the phase name
    # @return [Command::Phase]
    #   a phase object
    def phase(name, &block)
      unless @__phase__.has_key?(name)
        raise ArgumentError.new('Unknown phase name: "%s"' % name)
      end

      if block_given?
        block.call(@__phase__[name])
      end

      @__phase__[name]
    end
  end

  # Scenario is a class that controls flows and handles sequencial actions.
  class Scenario
    # import basic methods for object
    include ScenarioInterface

    # initial settings
    @requirements = Array.new
    @info = ScenarioDefinition.new
    @__phase__ = Hash.new

    class << self
      # import basic methods for class
      include ScenarioInterface

      attr_accessor :requirements
      attr_accessor :info
      attr_accessor :__phase__

      def inherited(subclass)
        # subclass inherits superclass's requirements
        subclass.requirements = @requirements.clone

        # subclass inherits superclass's info
        subclass.info = @info.clone

        # subclass inherits superclass's phases
        subclass.__phase__ = Hash.new
        @__phase__.each do |key, val|
          subclass.__phase__[key] = val.copy
        end
      end

      def scenario_name
        @info[:name]
      end

      # Make a new scenario class.
      #
      # @yieldparam block [Class]
      #   a new scenario class
      def make(&block)
        klass = Class.new(self)
        klass.instance_exec(&block)
        return klass
      end

      # Define a requirement of library. This is same as Kernel.require, but
      # loads it when the scenario runs.
      #
      # @param path [String]
      #   path that is required when the scenario runs
      # @return [void]
      def require(path)
        @requirements << path
      end

      # Run the scenario with the arguments.
      #
      # @param args [Array<Object>]
      #   scenario arguments
      def run(*args)
        self.new(*args).run
      end

      # Register the action to the phase.
      #
      # @param phase_name [Symbol]
      #   phase name
      # @param action [Symbol or Action]
      #   action name or item
      def define_action(phase_name, action, &b)
        # setup action item
        case action
        when Symbol
          item = Action.new(name: action)
        when Action
          item = action.copy
        else
          raise ArgumentError.new("%p is invalid action" % action)
        end

        # action customization
        b.call(item) if b

        # append it to the phase
        @__phase__[phase_name].define(item)
      end
    end

    # define default phase class
    define(:phase_class, Phase)

    # define default process context class
    define(:process_context_class, ProcessContext)

    attr_reader :args
    attr_accessor :model
    attr_accessor :info
    attr_reader :current_phase
    attr_accessor :exit_status
    attr_reader :running_thread

    forward! :class, :desc
    alias :name :scenario_name

    # Initialize a scenario object.
    def initialize(*args)
      # hold scenario arguments
      @args = args

      # copy requirements, info, phases from the class
      @requirements = self.class.requirements.clone
      @info = self.class.instance_variable_get(:@info).clone
      @__phase__ = self.class.instance_variable_get(:@__phase__).clone

      # setup scenario model
      if self.class.info[:model]
        @model = self.class.info[:model].new
      else
        @model = Model.new
      end
      @model[:scenario_name] = @info.scenario_name
      @model[:scenario_desc] = @info.desc

      # init
      @current_phase = nil
      @exit_status = true
      @running_thread = nil
    end

    # Run the lifecycle of command. This fires sequencial actions in each phase.
    #
    # @return [void]
    def run
      # raise an error when running thread exists already
      if @running_thread
        raise ScenarioError.new("Running thread exists already.")
      end

      @running_thread = Thread.current
      load_requirements
      execute_phases
      @running_thread = nil
      return self
    end

    # Push the phase action to the scenario.
    #
    # @param object [Action]
    #   action
    # @return [void]
    def <<(object)
      if @__phase__.empty?
        phase_name = :default
        define_phase(phase_name)
      else
        phase_name = @__phase__.keys.last
      end
      phase(phase_name) << object
    end

    # Exit running scenario and return the status.
    #
    # @return [void]
    def exit
      Log.debug('"%{name}" exits with status "%{status}".' % {name: name, status: @exit_status})

      if respond_to?(:exit_process, true)
        exit_process
      end
    end

    # Exit the running command and return failure status. Note that this
    # method enters termination phase before it exits.
    def abort(msg_or_exception, pos=caller(1).first)
      # setup abortion message
      msg = msg_or_exception.is_a?(Exception) ? msg_or_exception.message : msg_or_exception
      Log.fatal(msg, pos)

      # set exit status code
      @exit_status = false

      # do abort process
      if respond_to?(:abort_process, true)
        abort_process
      end

      # finally, exit the command
      exit
    end

    private

    # Load additional modules.
    #
    # @return [void]
    def load_requirements
      @requirements.each do |requirement|
        Kernel.require(requirement)
      end
    end

    # Enter the phase.
    #
    # @param phase_name [Symbol]
    #   the phase name that is entered
    # @return [void]
    def enter_phase(phase_name)
      Log.debug('"%{cmd}" has entered the phase "%{phase}".' % {cmd: name, phase: phase_name})
      @__phase__[phase_name].execute(self)
      Log.debug('"%{cmd}" has exited the phase "%{phase}".' % {cmd: name, phase: phase_name})
    end

    # Execute phases.
    #
    # @return [void]
    def execute_phases
      @__phase__.each do |phase_name, phase|
        @current_phase = phase
        enter_phase(phase_name)
      end
      @current_phase = nil
    end
  end
end
