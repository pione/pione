module Pione
  module Command
    # PioneActionExec is a command that executes action from outside of rule
    # engine.
    class PioneActionExec < BasicCommand
      #
      # command informations
      #

      define(:name, "exec")
      define(:desc, "Execute an action rule in literate action document")

      #
      # arguments
      #

      argument(:location) do |item|
        item.type    = :location
        item.desc    = "Location of action document"
        item.missing = "There are no action documents or packages."
      end

      argument(:name) do |item|
        item.type    = :string
        item.desc    = "Action name"
        item.missing = "There is no action name."
      end

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug

      option(:domain_dump) do |item|
        item.type = :location
        item.long = "--domain-dump"
        item.arg  = "LOCATION"
        item.desc = "Load the domain dump file"
      end

      option(:directory) do |item|
        item.type  = :location
        item.short = "-d"
        item.long  = "--directory PATH"
        item.desc  = "execute in the PATH"
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item << CommonAction.load_domain_dump
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :exec
      end

      execution(:exec) do |item|
        item.desc = "Update pacakge info files"

        item.process do
          if action = LiterateAction::Document.load(model[:location]).find(model[:name])
            action.execute(model[:domain_info], model[:directory])
          else
            cmd.abort("The action not found.")
          end
        end

        item.exception(Location::NotFound) do |e|
          cmd.abort(e)
        end
      end
    end

    PioneAction.define_subcommand("exec", PioneActionExec)
  end
end
