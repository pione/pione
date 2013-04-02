module Pione
  module Option
    # TupleSpaceProviderOption provides options for commands that make tuple
    # space provider agent.
    module TupleSpaceProviderOption
      extend OptionInterface
      use PresenceNotifierOption

      # --presence-notification-address
      option(
        "--presence-notification-address=255.255.255.255:%s" % Global.presence_port,
        "set the address for sending presence notifier"
      ) do |data, address|
        # clear addresses at first time
        unless @__option_notifier_address__
          @__option_notifier_address__ = true
          Global.presence_notification_addresses = []
        end
        # add the address
        address = address =~ /^broadcast/ ? address : "broadcast://%s" % address
        uri = URI.parse(address)
        uri.host = "255.255.255.255" if uri.host.nil?
        uri.port = Global.presence_port if uri.port.nil?
        Global.presence_notification_addresses << uri
      end
    end
  end
end
