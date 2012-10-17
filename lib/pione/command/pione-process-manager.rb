module Pione
  module Command
    class PioneProcessManager < BasicCommand
      include ProcessClient

      def run
        CONFIG.tuple_space_provider_mode = :enable
        super
      end
    end
  end
end
