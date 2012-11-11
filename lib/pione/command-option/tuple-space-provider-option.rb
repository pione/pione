module Pione
  module CommandOption
    module TupleSpaceProviderOption
      extend OptionInterface
      use_option_module PresenceNotifierOption

      # --notifier-address
      define_option(
        "--notifier-address=255.255.255.255:%s" % Global.presence_port,
        "set the address for sending presence notifier"
      ) do |address|
        address = address =~ /^broadcast/ ? address : "broadcast://%s" % address
        uri = URI.parse(address)
        uri.host = "255.255.255.255" if uri.host.nil?
        uri.port = Global.presence_port if uri.port.nil?
        @notifier_addresses << uri
      end
    end
  end
end
