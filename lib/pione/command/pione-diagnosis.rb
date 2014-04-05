module Pione
  module Command
    # `PioneDiagnosis` is a utility set for diagnosis.
    class PioneDiagnosis < BasicCommand
      #
      # informations
      #

      define(:name, "diagnosis")
      define(:desc, "PIONE diagnosis tools")

      #
      # requirements
      #

      require 'pione/command/pione-diagnosis-notification'
    end

    PioneCommand.define_subcommand("diagnosis", PioneDiagnosis)
  end
end
