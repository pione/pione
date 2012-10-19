module Pione
  module Command
    module OptionInterfaceSingleton
      # Makes options list.
      def self.extended(klass)
        klass.instance_variable_set(:@options, [])
      end

      # Defines an option for the command.
      def define_option(*args, &b)
        @options << [args, b]
      end

      # Returns options.
      def options
        @options
      end
    end

    # OptionInterface is for defining command options.
    module OptionInterface
      # Parses options.
      def parse_options
        OptionParser.new do |opt|
          self.class.options.each do |args, b|
            opt.on(*args, Proc.new{|*args| self.instance_exec(*args, &b)})
          end
          opt.version = Pione::VERSION
        end.parse!(ARGV)
      rescue OptionParser::InvalidOption => e
        e.args.each {|arg| $stderr.puts "Unknown option: #{arg}" }
        abort
      end

      # Validates options.
      # @return [void]
      #   true if options are valid.
      def validate_options
        # do nothing
      end
    end

    # BasicCommand is a base class for PIONE commands.
    class BasicCommand
      extend OptionInterfaceSingleton
      include OptionInterface

      # @api private
      def self.inherited(subclass)
        opts = options.clone
        subclass.instance_eval { @options = opts }
      end

      # Runs the command.
      def self.run
        cmd = self.new
        cmd.parse_options
        cmd.validate_options
        cmd.setup_front
        cmd.run
      end

      define_option('-d', '--debug', "debug mode") do |name|
        Pione.debug_mode = true
      end

      define_option('--[no-]color', 'color mode') do |str|
        bool = nil
        bool = true if str == "true"
        bool = false if str == "false"
        if bool.nil?
          puts "invalid color option: %s" % bool
          exit
        end
        Terminal.color_mode = bool
      end

      attr_reader :front

      # Setups font server.
      def setup_front
        Pione.set_front(create_front)
      end

      # Runs the command.
      def run
        raise NotImplementedError
      end

      private

      # Creates a front server.
      # @return [BasicFront]
      #   front server
      def create_front
        raise NotImplementedError
      end
    end
  end
end
