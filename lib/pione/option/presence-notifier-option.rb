module Pione
  module Option
    # PresenceNotifierOption provides options for presence notifiers.
    module PresenceNotifierOption
      extend OptionInterface

      # --show-presence-notifier
      option(
        "--show-presence-notifier",
        "show presence notifier informations"
      ) do |data|
        Global.show_presence_notifier = true
      end
    end
  end
end
