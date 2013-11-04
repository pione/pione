module Pione
  module Command
    # PioneAction is a command definition of "pione action" for executing
    # literate action.
    class PioneAction < BasicCommand
      #
      # basic informations
      #

      command_name "pione action"
      command_banner "execute an action in literate action document"
      PioneCommand.add_subcommand("action", self)

      #
      # options
      #

      use_option :color
      use_option :debug

      define_option(:domain) do |item|
        item.long = "--domain"
        item.desc = "use the domain information file"
        item.default = Location["./domain.dump"]
        item.value = lambda {|b| b}
      end

      define_option(:show) do |item|
        item.long = "--show"
        item.desc = "show the action without execution"
        item.value = lambda {|b| b}
      end

      define_option(:directory) do |item|
        item.short = "-d"
        item.long = "--directory PATH"
        item.desc = "execute in the PATH"
        item.value = lambda {|b| Location[b]}
      end

      #
      # command lifecycle: setup phase
      #

      setup :target
      setup :domain

      # Setup location of literate action document and action name.
      def setup_target
        abort("There are no literate action documents or packages.")  if @argv[0].nil?
        abort("Action name is needed.") if @argv[1].nil?
        @location = Location[@argv[0]]
        @name = @argv[1]
      end

      # Load a domain information file.
      def setup_domain
        if option[:domain].exist?
          @domain_info = System::DomainInfo.read(option[:domain])
        end
      end

      #
      # command lifecycle: execution phase
      #

      execute :exec

      # Update pacakge info files.
      def execute_exec
        if action = LiterateAction::Document.load(@location).find(@name)
          if option[:show]
            puts action.textize(@domain_info)
          else
            action.execute(@domain_info, option[:directory])
          end
        else
          abort(e.message)
        end
      end
    end
  end
end
