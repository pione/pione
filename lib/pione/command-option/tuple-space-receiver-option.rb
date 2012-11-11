module Pione
  module CommandOption
    module TupleSpaceReceiverOption
      extend OptionInterface
      use_option_module PresenceNotifierOption

      define_option("--presence-port=PORT", "set presence port number") do |port|
        Global.presence_port = port.to_i
      end
    end
  end
end
