module Pione
  module Command
    # PioneConfig is a command for configurating PIONE global variables.
    class PioneConfig < BasicCommand
      #
      # basic informations
      #

      command_name "pione-config"
      command_banner "config PIONE global variables"

      #
      # options
      #

      use_option :debug

      define_option(:get) do |item|
        item.long = "--get NAME"
        item.desc = "get the item value"
        item.action = Proc.new {|cmd, option, name|
          cmd.action_type = :get
          option[:name] = name
        }
      end

      define_option(:list) do |item|
        item.long = "--list"
        item.desc = "list all"
        item.action = Proc.new {|cmd, option, _|
          cmd.action_type = :list
        }
      end

      define_option(:set) do |item|
        item.long = "--set NAME VALUE"
        item.desc = "set the item"
        item.action = Proc.new {|cmd, option, name|
          cmd.action_type = :set
          option[:name] = name
        }
      end

      define_option(:unset) do |item|
        item.long = "--unset NAME VALUE"
        item.desc = "set the item"
        item.action = Proc.new {|cmd, option, name|
          cmd.action_type = :unset
          option[:name] = name
        }
      end

      define_option(:file) do |item|
        item.short = "-f"
        item.long = "--file PATH"
        item.desc = "config file path"
        item.default = Global.config_path
        item.value = lambda {|filepath| Pathname.new(filepath)}
      end

      #
      # command lifecycle: execution phase
      #

      execute :get => :get_item
      execute :list => :list_all
      execute :set => :set_item
      execute :unset => :unset_item

      def execute_get_item
        name = option[:name]

        if name
          config = Global::Config.new(option[:file])
          puts config.get(name)
        else
          abort("`--get` option requires an item name")
        end
      rescue Global::UnconfigurableVariableError
        abort("'%s' is not a configurable item name." % name)
      end

      def execute_list_all
        table = Hash.new

        Global.item.each do |key, item|
          if item.configurable?
            table[key] = item.init
          end
        end

        Global::Config.new(option[:file]).each do |name, value|
          table[name] = value
        end

        table.keys.sort.each do |name|
          puts "%s: %s" % [name, table[name]]
        end
      end

      def execute_set_item
        name = option[:name]
        value = @argv.first

        if name
          config = Global::Config.new(option[:file])
          config.set(name, value)
          config.save(option[:file])
        else
          abort("`--set` option requires an item name")
        end
      rescue Global::UnconfigurableVariableError
        abort("'%s' is not a configurable item name." % name)
      end

      def execute_unset_item
        name = option[:name]

        if name
          global = Global::Config.new(option[:file])
          global.unset(name)
          global.save(option[:file])
        else
          abort("`--unset` option requires an item name")
        end
      end
    end
  end
end
