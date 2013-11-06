module Pione
  module Command
    class PioneListParam < BasicCommand
      #
      # basic informations
      #

      command_name "pione list-param"
      command_banner "Show a list of parameters in the document or package."
      PioneCommand.add_subcommand("list-param", self)

      #
      # options
      #

      use_option :color
      use_option :debug

      define_option(:advanced) do |item|
        item.short = "-a"
        item.long = "--advanced"
        item.desc = "show advanced parameters"
        item.value = lambda {|b| b}
      end

      #
      # command lifecycle: setup phase
      #

      setup :target

      # Setup location of the target document.
      def setup_target
        abort("There are no documents or packages.")  if @argv[0].nil?
        @target_location = Location[@argv[0]]
      end

      #
      # command lifecycle: execution phase
      #

      execute :print_list

      # Print a list of parameters in the document.
      def execute_print_list
        # read package
        @package_handler = Package::PackageReader.read(@target_location)
        @env = @package_handler.eval(Lang::Environment.new)

        # print a list
        basic, advanced = Util::PackageParametersList.find(@env, @env.current_package_id)
        if basic.empty? and advanced.empty?
          puts "there are no user parameters in %s" % @env.current_package_id
        else
          if not(basic.empty?)
            print_by_block("Basic Parameters", basic, @env)
          end
          if not(advanced.empty?) and option[:advanced]
            print_by_block("Advanced Parameters", advanced, @env)
          end
        end
      rescue Package::InvalidPackage => e
        abort("Package error: " + e.message)
      rescue Lang::ParserError => e
        abort("Pione syntax error: " + e.message)
      rescue Lang::LangError => e
        abort("Pione language error: %s(%s)" % [e.message, e.class.name])
      end

      private

      #
      # helper methods
      #

      # Print parameters by block.
      def print_by_block(header, params, env)
        unless params.empty?
          puts "%s:" % header
          params.each do |param|
            puts "  %s := %s" % [param.name, param.value.eval(env).textize]
          end
        end
      end
    end
  end
end
