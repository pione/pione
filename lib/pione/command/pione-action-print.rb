module Pione
  module Command
    # `PioneActionPrint` is a command that prints action contents.
    class PioneActionPrint < BasicCommand
      #
      # basic informations
      #

      command_name "pione action print"
      command_banner "print action contents"

      #
      # options
      #

      use_option :color

      define_option(:domain) do |item|
        item.long = "--domain"
        item.desc = "use the domain information file"
        item.default = Location["./domain.dump"]
        item.value = lambda {|b| b}
      end

      #
      # command lifecycle: setup phase
      #

      setup :source
      setup :action_name
      setup :domain

      # Setup source location.
      def setup_source
        abort("There are no literate action documents or packages.")  if @argv[0].nil?
        @location = Location[@argv[0]]
      end

      # Setup action name.
      def setup_action_name
        abort("There is no action name.") if @argv[1].nil?
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

      execute :print

      # Print the action contents.
      def execute_print
        if action = LiterateAction::Document.load(@location).find(@name)
          puts action.textize(@domain_info)
        else
          abort("The action not found.")
        end
      rescue Location::NotFound => e
        abot(e.message)
      end
    end
  end
end
