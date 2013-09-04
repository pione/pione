module Pione
  module Command
    # CommandInfo is a strage of program informations.
    class CommandInfo
      attr_reader :name
      attr_reader :tail
      attr_reader :banner

      def initialize
        @name = nil
        @tail = nil
        @banner = banner
      end

      # Set progaram name.
      def set_name(name)
        @name = name
      end

      # Set program parameters.
      def set_tail(&tail)
        @tail = tail
      end

      # Set program banner.
      #
      # @param banner [String]
      #   banner message
      # @return [void]
      def set_banner(banner)
        @banner = banner
      end

      # Setup program name. If the setup process is failed, program name is not
      # changed.
      #
      # @param cmd [BasicCommand]
      #   command
      # @return [void]
      def setup(cmd)
        $PROGRAM_NAME = "%s %s" % [@name, @tail ? @tail.call(cmd) : ""]
      end
    end

    # BasicCommand is a base class for PIONE commands.
    class BasicCommand < PioneObject
      @info = CommandInfo.new
      @option = Option.new(@info)
      @pre_preparations = []
      @preparations = []
      @post_preparations = []
      @pre_starts = []
      @starts = []
      @post_starts = []
      @pre_terminations = []
      @terminations = []
      @post_terminations =[]

      class << self
        attr_reader :info
        attr_reader :option
        attr_reader :pre_preparations
        attr_reader :preparations
        attr_reader :post_preparations
        attr_reader :pre_starts
        attr_reader :starts
        attr_reader :post_starts
        attr_reader :pre_terminations
        attr_reader :terminations
        attr_reader :post_terminations

        # @api private
        def inherited(subclass)
          parent_option = self.option
          subclass.instance_eval do
            @info = CommandInfo.new
            @option = Option.new(@info)
          end
          setter = lambda{|name, data| subclass.instance_variable_set(name, data.clone)}
          setter.call(:@pre_preparations, self.pre_preparations)
          setter.call(:@preparations, self.preparations)
          setter.call(:@post_preparations, self.post_preparations)
          setter.call(:@pre_starts, self.pre_starts)
          setter.call(:@starts, self.starts)
          setter.call(:@post_starts, self.post_starts)
          setter.call(:@pre_terminations, self.pre_terminations)
          setter.call(:@terminations, self.terminations)
          setter.call(:@post_terminations, self.post_terminations)
        end

        # Define command informations.
        def define_info(&b)
          @info.instance_eval(&b)
        end

        # Define command option.
        def define_option(&b)
          @option.instance_eval(&b)
        end

        # Define a preparation process.
        def prepare(type=nil, &b)
          case type
          when :pre
            @pre_preparations << b
          when :post
            @post_preparations << b
          else
            @preparations << b
          end
        end

        # Define a start process.
        def start(type=nil, &b)
          case type
          when :pre
            @pre_starts << b
          when :post
            @post_starts << b
          else
            @starts << b
          end
        end

        # Define a termination process.
        def terminate(type=nil, &b)
          case type
          when :pre
            @pre_terminations << b
          when :post
            @post_terminations << b
          else
            @terminations << b
          end
        end

        # Run the command.
        def run(argv)
          self.new(argv).run
        end
      end

      forward! :class, :option, :info

      def initialize(argv)
        @argv = argv
      end

      # Run the command.
      def run
        receiver = self
        caller = lambda {|name| self.class.__send__(name).each{|proc| receiver.instance_eval(&proc)}}
        caller.call(:pre_preparations)
        caller.call(:preparations)
        caller.call(:post_preparations)
        caller.call(:pre_starts)
        caller.call(:starts)
        caller.call(:post_starts)
        call_terminations
      end

      def call_terminations
        receiver = self
        caller = lambda  do |name|
          self.class.__send__(name).reverse.each do |proc|
            puts "%s(%s):%s:%s" % [info.name, name, *proc.source_location] if Pione.debug_mode?
            receiver.instance_eval(&proc)
          end
        end
        caller.call(:pre_terminations)
        caller.call(:terminations)
        caller.call(:post_terminations)
      end

      prepare(:pre) do
        # set signal trap
        Signal.trap(:INT) do
          begin
            call_terminations
          rescue DRb::ReplyReaderThreadError
            # ignore reply reader error
          end
        end

        Signal.trap(:TERM) { call_terminations }

        # parse options
        option.parse(@argv)
      end

      prepare do
        # validate options
        option.check
      end

      prepare(:post) do
        # setup process name
        info.setup(self)
      end

      terminate(:post) do
        Global.monitor.synchronize do
          # exit with no exception
          exit Global.exit_status
        end
      end
    end
  end
end
