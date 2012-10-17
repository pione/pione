module Pione
  module Command
    class BasicCommand
      @options = []

      def self.inherited(subclass)
        options = @options.clone
        subclass.instance_eval do
          @options = options
        end
      end

      def self.run
        DRb.start_service
        cmd = self.new
        cmd.parse_options
        cmd.run
      end

      def self.define_option(*args, &b)
        @options << [args, b]
      end

      def self.options
        @options
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

      def parse_options
        parser = OptionParser.new do |opt|
          self.class.options.each do |args, b|
            opt.on(*args, Proc.new{|*args| self.instance_exec(*args, &b)})
          end
          opt.version = Pione::VERSION
        end.parse!(ARGV)
      rescue OptionParser::InvalidOption => e
        e.args.each {|arg| $stderr.puts "Unknown option: #{arg}" }
        abort
      end
    end
  end
end
