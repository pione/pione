module Pione
  module CommandOption
    module PresenceNotifierOption
      extend OptionInterface

      # --show-presence-notifier
      define_option(
        "--show-presence-notifier",
        "show presence notifier informations"
      ) do
        Global.show_presence_notifier = true
      end
    end
  end
end
