module Pione
  module Command
    # `PioneConfigList` is a command that lists PIONE global variables.
    class PioneConfigList < BasicCommand
      #
      # informations
      #

      define(:name, "list")
      define(:desc, "List PIONE global variables")

      #
      # options
      #

      option CommonOption.debug
      option PioneConfigOption.file

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :collect_items
        item << :print
      end

      execution(:collect_items) do |item|
        item.desc = "List"

        # make items table
        item.assign(:table) {Hash.new}

        # push configurable global items
        item.process do
          Global.item.each do |key, item|
            if item.configurable?
              model[:table][key] = item.init
            end
          end
        end

        # push items in config file
        item.process do
          Global::Config.new(model[:file]).each do |name, value|
            model[:table][name] = value
          end
        end
      end

      execution(:print) do |item|
        item.desc = "Print a list of configurable items"

        item.process do
          model[:table].keys.sort.each do |name|
            puts "%s: %s" % [name, model[:table][name]]
          end
        end
      end
    end

    PioneConfig.define_subcommand("list", PioneConfigList)
  end
end
