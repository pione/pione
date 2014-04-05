module Pione
  module Command
    # `PioneLang` is a utility set for PIONE language.
    class PioneLang < BasicCommand
      #
      # informations
      #

      define(:name, "lang")
      define(:desc, "PIONE language utilities")

      #
      # requirements
      #

      require 'pione/command/pione-lang-interactive'
      require 'pione/command/pione-lang-check-syntax'
    end

    PioneCommand.define_subcommand("lang", PioneLang)
  end
end
