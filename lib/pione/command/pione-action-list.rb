module Pione
  module Command
    # PioneActionList is a command definition of "pione action:list" for listing
    # literate actions.
    class PioneActionList < BasicCommand
      #
      # basic informations
      #

      command_name "pione action:list"
      command_banner "show list of action names in document"
      PioneCommand.add_subcommand("action:list", self)

      #
      # options
      #

      use_option :color

      #
      # command lifecycle: setup phase
      #

      setup :target

      # Setup location of literate action document and action name.
      def setup_target
        abort("There are no literate action documents or packages.")  if @argv[0].nil?
        @location = Location[@argv[0]]
      end

      #
      # command lifecycle: execution phase
      #

      execute :show_list

      # Show list of action names.
      def execute_show_list
        names = LiterateAction::Document.load(@location).action_names.sort
        if names.empty?
          abort("no action names in %s" % @location.address)
        else
          names.each {|name| puts name}
        end
      end
    end
  end
end
