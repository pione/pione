module Pione
  module Option
    # CommonOption provides common options for pione commands.
    module CommonOption
      extend OptionInterface

      define(:color) do |item|
        item.long = '--[no-]color'
        item.desc = 'turn on/off color mode'
        item.action = proc {|_, bool| Sickill::Rainbow.enabled = bool}
      end

      define(:daemon) do |item|
        item.long = "--daemon"
        item.desc = "turn on daemon mode"
        item.default = false
        item.value = true
      end

      define(:debug) do |item|
        item.long = '--debug'
        item.desc = "turn on debug mode"
        item.action = proc {Pione.debug_mode = true}
      end

      define(:my_ip_address) do |item|
        item.long = "--my-ip-address=ADDRESS"
        item.desc = "set my IP address"
        item.action = proc {|_, address| Global.my_ip_address = address}
      end

      define(:presence_notification_address) do |item|
        item.long = "--presence-notification-address=255.255.255.255:%s" % Global.presence_port
        item.desc = "set the address for sending presence notifier"
        item.action = proc do |_, address|
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

      define(:show_communication) do |item|
        item.long = '--show-communication'
        item.desc = "show object communication"
        item.action = proc {Global.show_communication = true}
      end

      define(:show_presence_notifier) do |item|
        item.long = "--show-presence-notifier"
        item.desc = "show presence notifier informations"
        item.action = proc {Global.show_presence_notifier = true}
      end
    end
  end
end
