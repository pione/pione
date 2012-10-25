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
        # @return [Symbol]
        #   all item names
        def all_names
          @__names__
        end

        # Initializes global values.
        # @return [void]
        def init
          @__config__.each do |name, config_name|
            if val = Global.config[config_name]
              instance_variable_set("@%s" % name, val)
            end
          end

          @__initializer__.each do |name, action|
            unless instance_variable_get("@%s" % name)
              instance_variable_set("@%s" % name, action.call)
            end
          end
        end
      end

      extend GlobalInterface

      define_item(:config, true, Config.new("~/.pione/config.yml"))

      # .pione dir
      define_item(:dot_pione_dir, true) do
        Pathname.new("~/.pione").expand_path.tap{|path|
          path.mkpath unless path.exist?
        }
      end

      # config path
      define_item(:config_path, true) do
        Global.dot_pione_dir + "config.yml"
      end

      # root of working directory
      define_item(:working_directory_root, true) do
        Pathname.new(File.join(Dir.tmpdir, "pione-wd")).tap{|path|
          path.mkpath unless path.exist?
        }
      end

      # working directory
      define_item(:working_directory, false) do
        Pathname.new(Dir.mktmpdir(nil, Global.working_directory_root))
      end

      # front server
      define_item(:front, false)

      # tuple space provider uri
      define_item(:tuple_space_provider_uri, false)

      # tuple space receiver uri
      define_item(:tuple_space_receiver_uri, false)

      # disconnect time for tuple space receiver
      define_item(:tuple_space_receiver_disconnect_time, true, 180)

      # presence port
      define_item(:presence_port, true, 55000)

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
      define_item(:relay_port, true, 54002)

      # certname for relay server
      define_item(:relay_ssl_certname, true, [["CN", "localhost.localhost"]])
    end
  end
end
