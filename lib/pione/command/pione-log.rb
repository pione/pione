module Pione
  module Command
    # `PioneLog` is a command set of log utilities.
    class PioneLog < BasicCommand
      #
      # basic informations
      #

      define(:name, "log")
      define(:desc, "Log utilities")

      #
      # requirements
      #

      require 'pione/command/pione-log-format'
      require 'pione/command/pione-log-list-id'
    end

    # `PioneLogArgument` provides common arguments for `pione log` subcommands.
    module PioneLogArgument
      extend Rootage::ArgumentCollection

      define(:log_location) do |item|
        item.type    = :location
        item.heading = "location"
        item.desc    = "Location of PIONE raw log"

        item.process do |loc|
          test(not(loc.exist?))
          cmd.abort("File not found in the location: %s" % loc.uri)
        end
      end
    end

    PioneCommand.define_subcommand("log", PioneLog)
  end
end
