module Pione
  module System
    # Global is a table of global variables in PIONE system. It defines item
    # names, default values, and configuration conditions. You can set and get
    # value by calling item named method.
    module Global
      # GlobalInterface provides item definition methods.
      module GlobalInterface
        # @api private
        def self.extended(mod)
          mod.instance_variable_set(:@__names__, [])
          mod.instance_variable_set(:@__config__, {})
          mod.instance_variable_set(:@__initializer__, [])
        end

        # Defines a global variable item.
        # @param [Symbol] name
        #   item name
        # @param [Boolean] configurable
        #   this means the item is configurable if true
        # @param [Object] val
        #   default value
        # @return [void]
        def define_item(name, config, val=nil, &b)
          @__names__ << name
          if config
            @__config__[name] = config.kind_of?(TrueClass) ? name : config
          end

          singleton_class.module_eval do |mod|
            # value reader
            define_method(name) do
              instance_variable_get("@%s" % name)
            end

            # value writer
            define_method("set_%s" % name) do |val|
              instance_variable_set("@%s" % name, val)
            end

            # value writer
            define_method("%s=" % name) do |val|
              instance_variable_set("@%s" % name, val)
            end
          end

          instance_variable_set("@%s" % name, val) if val
          @__initializer__ << [name, b] if block_given?
        end

        # Returns all item names.
        #
        # @return [Symbol]
        #   all item names
        def all_names
          @__names__
        end

        # Initializes global values.
        # @return [void]
        def init
          @__initializer__.each do |name, action|
            unless instance_variable_get("@%s" % name)
              instance_variable_set("@%s" % name, action.call)
            end
          end
        end

        # Return the table of all configurations.
        #
        # @return [Hash<Symbol, Object>]
        def all
          Hash[all_names.map {|name| [name, Global.send(name)]}]
        end
      end

      extend GlobalInterface

      #
      # debug
      #

      # show distributed object communication
      define_item(:show_communication, false, false)

      # show presence notifier
      define_item(:show_presence_notifier, false, false)

      #
      # system
      #

      # @!method monitor
      # Global monitor object for PIONE system.
      #
      # @return [Monitor]
      #   monitor object
      define_item(:monitor, false, Monitor.new)

      # .pione dir
      define_item(:dot_pione_dir, true) do
        Pathname.new("~/.pione").expand_path.tap {|path|
          path.mkpath unless path.exist?
        }
      end

      # config path
      define_item(:config_path, true) do
        Global.dot_pione_dir + "config.yml"
      end

      # root of working directory
      define_item(:working_directory_root, true) do
        Pathname.new(File.join(Dir.tmpdir, "pione-wd-" + Etc.getlogin)).tap {|path|
          path.mkpath unless path.exist?
        }
      end

      # working directory
      define_item(:working_directory, false) do
        Pathname.new(Dir.mktmpdir(nil, Global.working_directory_root))
      end

      # root of file cache directory
      define_item(:file_cache_directory_root, true) do
        Pathname.new(File.join(Dir.tmpdir, "pione-file-cache-" + Etc.getlogin)).tap {|path|
          path.mkpath unless path.exist?
        }
      end

      # file cache directory
      define_item(:file_cache_directory, false) do
        Pathname.new(Dir.mktmpdir(nil, Global.file_cache_directory_root))
      end

      # system front server
      define_item(:front, false)

      # This means the process's IP address.
      define_item(:my_ip_address, true) do
        Util.my_ip_address_list.first
      end

      # This means current working directory. The directory is defined by the
      # following rule:
      # - 1. if environment variable "PWD" is defined, use it
      # - 2. if "pwd" command exists, use the command result with logical option
      # - 3. otherwise Dir.pwd
      define_item(:pwd, false) do
        (ENV["PWD"] || `pwd -L`.chomp || Dir.pwd)
      end

      #
      # pione-client
      #

      # client-front port range begin
      define_item(:client_front_port_range_begin, true, 40000)

      # client-front port range end
      define_item(:client_front_port_range_end, true, 40999)

      # client-front port range
      define_item(:client_front_port_range, false) do
        Range.new(
          Global.client_front_port_range_begin,
          Global.client_front_port_range_end
        )
      end

      #
      # pione-broker
      #

      # broker-front port range begin
      define_item(:broker_front_port_range_begin, true, 41000)

      # broker-front port range end
      define_item(:broker_front_port_range_end, true, 41999)

      # broker-front port range
      define_item(:broker_front_port_range, false) do
        Range.new(
          Global.broker_front_port_range_begin,
          Global.broker_front_port_range_end
        )
      end

      #
      # provider & receiver
      #

      # presence port
      define_item(:presence_port, true, 56000)

      #
      # pione-tuple-space-provider
      #

      # tuple space provider uri
      define_item(:tuple_space_provider_uri, false)

      # provider-front port range begin
      define_item(:tuple_space_provider_front_port_range_begin, true, 42000)

      # provider-front port range end
      define_item(:tuple_space_provider_front_port_range_end, true, 42999)

      # provider-front port range
      define_item(:tuple_space_provider_front_port_range, false) do
        Range.new(
          Global.tuple_space_provider_front_port_range_begin,
          Global.tuple_space_provider_front_port_range_end
        )
      end

      # presence notification address
      define_item(:presence_notification_addresses, true) do
        [URI.parse("broadcast://%s:%s" % ["255.255.255.255", Global.presence_port])]
      end

      #
      # pione-tuple-space-receiver
      #

      # tuple space receiver uri
      define_item(:tuple_space_receiver_uri, false)

      # receiver-front port range begin
      define_item(:tuple_space_receiver_front_port_range_begin, true, 43000)

      # receiver-front port range end
      define_item(:tuple_space_receiver_front_port_range_end, true, 43999)

      # receiver-front port range
      define_item(:tuple_space_receiver_front_port_range, false) do
        Range.new(
          Global.tuple_space_receiver_front_port_range_begin,
          Global.tuple_space_receiver_front_port_range_end
        )
      end

      # disconnect time for tuple space receiver
      define_item(:tuple_space_receiver_disconnect_time, true, 180)

      #
      # relay
      #

      # relay user database path
      define_item(:relay_client_db_path, true) do
        Global.dot_pione_dir + "relay-client.db"
      end

      # relay client database object
      define_item(:relay_client_db, false)

      # relay account database path
      define_item(:relay_account_db_path, true) do
        Global.dot_pione_dir + "relay-account.db"
      end

      # relay account database object
      define_item(:relay_account_db, false)

      # relay server's realm
      define_item(:relay_realm, true)

      # relay uri
      define_item(:relay_uri, false)

      # relay port
      define_item(:relay_port, true, 56001)

      # certname for relay server
      define_item(:relay_ssl_certname, true, [["CN", "localhost.localhost"]])

      # relay-front port range begin
      define_item(:relay_front_port_range_begin, true, 44000)

      # relay-front port range end
      define_item(:relay_front_port_range_end, true, 44999)

      # relay-front port range
      define_item(:relay_front_port_range, false) do
        Range.new(
          Global.relay_front_port_range_begin,
          Global.relay_front_port_range_end
        )
      end

      # relay-proxy port range begin
      define_item(:relay_proxy_port_range_begin, true, 45000)

      # relay-proxy port range end
      define_item(:relay_proxy_port_range_end, true, 45999)

      # relay-proxy port range
      define_item(:relay_proxy_port_range, false) do
        Range.new(
          Global.relay_proxy_port_range_begin,
          Global.relay_proxy_port_range_end
        )
      end

      # relay-client authentication timeout second
      define_item(:relay_client_auth_timeout_sec, true, 5)

      # relay tuple space server
      define_item(:relay_tuple_space_server, false)

      # relay-transmitter proxy side port range begin
      define_item(:relay_transmitter_proxy_side_port_begin, true, 46000)

      # relay-transmitter proxy side port range end
      define_item(:relay_transmitter_proxy_side_port_end, true, 46999)

      # relay-transmitter proxy side port range
      define_item(:relay_transmitter_proxy_side_port_range, false) do
        Range.new(
          Global.relay_transmitter_proxy_side_port_begin,
          Global.relay_transmitter_proxy_side_port_end
        )
      end

      # relay-receiver
      define_item(:relay_receiver, false)

      #
      # task worker
      #

      # task-worker-front port range begin
      define_item(:task_worker_front_port_range_begin, true, 50000)

      # task-worker-front port range end
      define_item(:task_worker_front_port_range_end, true, 54999)

      # task-worker-front port range
      define_item(:task_worker_front_port_range, false) do
        Range.new(
          Global.task_worker_front_port_range_begin,
          Global.task_worker_front_port_range_end
        )
      end

      #
      # input generator
      #
      define_item(:input_generator_stream_check_timespan, true, 3)
    end
  end
end
