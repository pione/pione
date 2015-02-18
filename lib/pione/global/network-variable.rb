module Pione
  module Global
    #
    # notification
    #

    define_internal_item(:default_notification_target_host) do |item|
      item.desc = "default notification target host"
      item.init = "255.255.255.255"
    end

    define_internal_item(:default_notification_target_port) do |item|
      item.desc = "default notification target port number"
      item.init = 56000
    end

    define_external_item(:notification_targets) do |item|
      item.desc = "notification target addresses"
      item.init = [Notification::Address.default_target_address]
      item.define_updater do |addresses|
        if addresses.is_a?(String)
          addresses.split(",").map do |address|
            Notification::Address.target_address_to_uri(address)
          end
        else
          addresses
        end
      end
    end

    define_internal_item(:default_notification_receiver_host) do |item|
      item.type = :string
      item.desc = "default notification receiver host"
      item.init = "0.0.0.0"
    end

    define_internal_item(:default_notification_receiver_port) do |item|
      item.desc = "default notification receiver port number"
      item.init = 56000
    end

    define_external_item(:notification_receivers) do |item|
      item.desc = "notification receiver addresses"
      item.init = [Notification::Address.default_receiver_address]
      item.define_updater do |addresses|
        if addresses.is_a?(String)
          addresses.split(",").map do |address|
            Notification::Address.receiver_address_to_uri(address.strip)
          end
        else
          addresses
        end
      end
    end

    define_external_item(:notification_listener_front_port) do |item|
      item.type = :integer
      item.desc = "front port number for notification listener"
      item.init = 55500
    end

    define_computed_item(:notification_listener,
      [:communication_address, :notification_listener_front_port]) do |item|
      item.desc = "Address of notification listener"
      item.define_updater do
        "druby://%s:%s" % [Global.communication_address, Global.notification_listener_front_port]
      end
    end

    #
    # communication
    #

    # This is the IP address of this system. Note that you should select one IP
    # address even if system has multiple addresses.
    define_external_item(:communication_address) do |item|
      item.desc = "IP address for interprocess communication"
      item.init = Util::IPAddress.myself
    end

    #
    # tuple space server
    #

    define_external_item(:tuple_space_broker_front_port_range_begin) do |item|
      item.desc = "Begin port number of tuple space broker"
      item.type = :integer
      item.init = 35000
    end

    define_external_item(:tuple_space_broker_front_port_range_end) do |item|
      item.desc = "End port number of tuple space broker"
      item.type = :integer
      item.init = 35100
    end

    define_computed_item(:tuple_space_broker_front_port_range,
      [:tuple_space_broker_front_port_range_begin, :tuple_space_broker_front_port_range_end]) do |item|
      item.desc = "port range of tuple space broker"
      item.define_updater do
        Range.new(
          Global.tuple_space_broker_front_port_range_begin,
          Global.tuple_space_broker_front_port_range_end)
      end
    end
  end
end
