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
      #
      # @param name [String]
      #   process name
      # @param b [Proc]
      #   process tail block
      # @return [void]
      def set_name(name, &b)
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

    # CommandOption is a class for holding option data set.
    class CommandOption < PioneObject
      def_delegators :@data, :[], :[]=

      # Creata a command option context.
      #
      # @param command_info [CommandInfo]
      #   command informations
      def initialize(command_info)
        extend Option::OptionInterface
        @command_info = command_info
        @data = {}
      end

      # Parse the command options.
      #
      # @return [void]
      def parse(argv)
        OptionParser.new do |opt|
          # set banner
          opt.banner = "Usage: %s [options]" % opt.program_name
          opt.banner << "\n" + @command_info.banner if @command_info.banner

          # set version
          opt.version = Pione::VERSION

          # set default values
          default_table.each do |key, value|
            @data[key] = value
          end

          # set options
          definitions.sort{|a,b| a.first <=> b.first}.each do |args, b|
            opt.on(*args, Proc.new{|*args| self.instance_exec(@data, *args, &b)})
          end
        end.parse!(argv)
      rescue OptionParser::InvalidOption => e
        e.args.each {|arg| $stderr.puts "Unknown option: %s" % arg }
        abort
      rescue OptionParser::MissingArgument => e
        abort(e.message)
      end

      # Check validness of the command options.
      #
      # @return [void]
      def check
        validators.each do |validator|
          validator.call(@data)
        end
      end
    end

    # BasicCommand is a base class for PIONE commands.
    class BasicCommand < PioneObject
      @info = CommandInfo.new
      @option = CommandOption.new(@info).tap {|x| x.use Option::CommonOption}
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
            @option = CommandOption.new(@info).tap {|x| x.use parent_option}
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
        #
        # @param b [Proc]
        #   evaluation content in the context of option definition
        # @return [void]
        #
        # @example
        #   class Cmd < BasicCommand
        #     define_info do
        #       set_name   "test"   # set process name
        #       set_banner "sample" # set banner message
        #     end
        #   end
        def define_info(&b)
          @info.instance_eval(&b)
        end

        # Define command option.
        #
        # @param b [Proc]
        #    context of the option definition
        #
        # @example
        #   class Cmd < BasicCommand
        #     define_option do
        #       option("-t", "--test", "test option") do |data, arg1|
        #         data[:test] = true
        #       end
        #     end
        #   end
        def define_option(&b)
          @option.instance_eval(&b)
        end

        # Define a preparation process.
        #
        # @param type [Symbol]
        #   preparation type
        # @return [void]
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
        #
        # @param type [Symbol]
        #   start type
        # @return [void]
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
        #
        # @param type [Symbol]
        #   termination type
        # @return [void]
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
        #
        # @return [void]
        def run(argv)
          self.new(argv).run
        end
      end

      forward! :class, :option, :info

      def initialize(argv)
        @argv = argv
      end

      # Run the command.
      #
      # @return [void]
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
