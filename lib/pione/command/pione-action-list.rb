module Pione
  module Command
    # PioneActionList is a command definition of "pione action:list" for listing
    # literate actions.
    class PioneActionList < BasicCommand
      #
      # basic informations
      #

      command_name "pione action list"
      command_banner "list action names in document"

      #
      # options
      #

      use_option :color

      define_option(:compact) do |item|
        item.long = "--compact"
        item.desc = "one line list"
        item.default = false
        item.value = lambda {|b| b}
      end

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
          if option[:compact]
            puts names.join(" ")
          else
            names.each {|name| puts name}
          end
        end
      end
    end
  end
end
