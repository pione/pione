module Pione
  module Command
    # OptionInterface provides methods for defining options.
    module ClassInterface
      # Returns the program name.
      def program_name
        [@program_name, @program_name_block]
      end

      # Sets progaram name and visible options.
      def set_program_name(program_name, &b)
        @program_name = program_name
        @program_name_block = block_given? ? b : Proc.new{""}
      end

      # Returns the program message.
      def program_message
        @program_message
      end

      # Sets program message.
      def set_program_message(message)
        @program_message = message
      end
    end

    module InstanceInterface
      # Returns program name.
      # @return [String]
      #   program name
      def program_name
        name, b = self.class.program_name
        tail = self.instance_exec(&b)
        "%s %s" % [name, tail]
      end

      # Returns program message.
      # @return [String]
      #   program message
      def program_message
        self.class.program_message
      end
    end

    # BasicCommand is a base class for PIONE commands.
    class BasicCommand < PioneObject
      extend ClassInterface
      include InstanceInterface
      extend CommandOption::OptionInterface
      use_option_module CommandOption::CommonOption

      # @api private
      def self.inherited(subclass)
        opts = command_options.clone
        subclass.instance_eval { @command_options = opts }
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

      # Parses options.
      # @return [void]
      def parse_options
        parser = OptionParser.new do |opt|
          opt.banner = "Usage: %s [options]" % opt.program_name
          opt.banner << "\n" + program_message if program_message

          self.class.command_options.values.sort.each do |args, b|
            opt.on(*args, Proc.new{|*args| self.instance_exec(*args, &b)})
          end
          opt.version = Pione::VERSION
        end

        parser.parse!(ARGV)
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
        Signal.trap(:INT) do
          begin
            terminate
          rescue DRb::ReplyReaderThreadError
            # ignore reply reader error
          end
        end
      end

      # Starts the command activity. This method should be overridden in subclasses.
      # @return [void]
      def start
        raise NotImplementedError
      end

      def terminate
        exit
      end
    end
  end
end
