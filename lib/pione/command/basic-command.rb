module Pione
  module Command
    # OptionInterface provides methods for defining options.
    module OptionInterface
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

    # BasicCommand is a base class for PIONE commands.
    class BasicCommand < PioneObject
      extend OptionInterface

      #
      # common options
      #

      define_option('-d', '--debug', "debug mode") do |name|
        Pione.debug_mode = true
      end

      define_option('--show-communication') do |show|
        Global.show_communication = true
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

      # @api private
      def self.inherited(subclass)
        opts = options.clone
        subclass.instance_eval { @options = opts }
      end

      # @api private
      def self.program_name
        [@program_name, @b]
      end

      # Sets progaram name and visible options.
      def self.set_program_name(program_name, &b)
        @program_name = program_name
        if block_given?
          @b = b
        else
          @b = Proc.new{""}
        end
      end

      # Runs the command.
      def self.run(*args)
        self.new(*args).run
      end

      # Runs the command.
      def run
        parse_options
        validate_options
        prepare
        $PROGRAM_NAME = program_name
        start
      end

      private

      def program_name
        name, b = self.class.program_name
        tail = self.instance_exec(&b)
        "%s %s" % [name, tail]
      end

      # Parses options.
      # @return [void]
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
      rescue OptionParser::MissingArgument => e
        abort(e.message)
      end

      # Validates options. Override this method if subclasses should check
      # options.
      # @return [void]
      def validate_options
        # do nothing
      end

      # Prepares for activity. Override this method if subclass should prepare
      # before command activity.
      # @return [void]
      def prepare
        # do nothing
      end

      # Starts the command activity. This method should be overridden in subclasses.
      # @return [void]
      def start
        raise NotImplementedError
      end

      def terminate
        # do nothing
      end
    end
  end
end
