module Pione
  module CommandOption
    module DaemonOption
      extend OptionInterface

      # --daemon
      define_option("--daemon", "turn on daemon mode") do
        @daemon = true
      end
    end
  end
end
