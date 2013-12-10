module Pione
  module Command
    # PioneActionExec is a command that executes action from outside of rule
    # engine.
    class PioneActionExec < BasicCommand
      #
      # basic informations
      #

      command_name "pione action exec"
      command_banner "execute an action in literate action document"

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

      define_option(:directory) do |item|
        item.short = "-d"
        item.long = "--directory PATH"
        item.desc = "execute in the PATH"
        item.value = lambda {|b| Location[b]}
      end

      #
      # command lifecycle: setup phase
      #

      setup :source
      setup :action_name
      setup :domain

      # Setup location of literate action document and action name.
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

      execute :exec

      # Update pacakge info files.
      def execute_exec
        if action = LiterateAction::Document.load(@location).find(@name)
          action.execute(@domain_info, option[:directory])
        else
          abort("The action not found.")
        end
      rescue Location::NotFound => e
        abot(e.message)
      end
    end
  end
end
