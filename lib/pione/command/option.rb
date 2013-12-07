module Pione
  module Command
    # OptionItem is an option item for PIONE command.
    class OptionItem < StructX
      member :name      # option name
      member :short     # short option (same as standard OptionParser)
      member :long      # long option (same as standard OptionParser)
      member :desc      # option description (same as standard OpionParser)
      member :default   # default value
      member :value     # value
      member :values    # ???
      member :action    # option action
      member :validator # option validator
      member :requisite # requisite option flag
    end

    # OptionInterface provides basic methods for option modules. All option
    # modules should be extended by this.
    module OptionInterface
      attr_reader :items

      # Define a new option for the command.
      def define(name, &b)
        item = OptionItem.new.tap do |item|
          item.name = name
          b.call(item)
        end

        if self.kind_of?(Module)
          singleton_class.send(:define_method, name) {item}
        else
          @items << item
        end
      end

      # Install the option module with configuration +option+.
      def use(item_name, option={})
        @items << CommonOption.send(item_name).set(option)
      end
    end

    # OptionDefinition is a class for holding option definitions.
    class OptionDefinition
      attr_accessor :parser_mode

      # Creata a command option context.
      def initialize
        extend OptionInterface
        @items = []      # option item definitions
        @default = {}    # default value table
        @validators = [] # option validators
        @parser_mode = :parse!
      end

      def item(name)
        @items.find {|item| item.name == name}
      end

      # Parse the command options.
      def parse(argv, cmd)
        data = Hash.new

        # parse options
        OptionParser.new do |opt|
          # set banner
          opt.banner = "Usage: %s [options]" % cmd.command_name
          opt.banner << "\n\n" + cmd.command_banner + "\n" if cmd.command_banner

          # set version
          opt.program_name = cmd.command_name
          opt.version = Pione::VERSION

          # default values
          @items.each {|item| data[item.name] = item.default if item.default}
          data.merge!(@default)

          # setup option parser
          @items.sort{|a,b| a.long <=> b.long}.each {|item| setup_item(cmd, opt, data, item)}
        end.send(@parser_mode, argv)

        # check option's validness
        check(data)

        return data
      end

      # Define the default value.
      def default(name, value)
        @default[name] = value
      end

      def validate(&b)
        @validators << b
      end

      private

      # Setup the option item.
      def setup_item(cmd, opt, data, item)
        defs = [item.short, item.long, item.desc].compact
        [ :setup_item_action,
          :setup_item_values,
          :setup_item_value,
          :setup_item_static_value
        ].find {|method_name| send(method_name, cmd, opt, data, item, defs)}
      end

      def setup_item_action(cmd, opt, data, item, defs)
        if item.action
          opt.on(*defs, Proc.new{|*args| self.instance_exec(cmd, data, *args, &item.action)})
        end
      end

      def setup_item_values(cmd, opt, data, item, defs)
        if item.values.kind_of?(Proc)
          opt.on(*defs, Proc.new{|*args| data[item.name] << self.instance_exec(*args, &item.values)})
        end
      end

      def setup_item_value(cmd, opt, data, item, defs)
        case item.value
        when Proc
          opt.on(*defs, Proc.new{|*args| data[item.name] = self.instance_exec(*args, &item.value)})
        when :as_is
          opt.on(*defs, Proc.new{|*args| data[item.name] = args.first})
        end
      end

      def setup_item_static_value(cmd, opt, data, item, defs)
        if item.value
          opt.on(*defs, Proc.new{ data[item.name] = item.value})
        end
      end

      # Check validness of the command options.
      def check(data)
        # check requisite options
        @items.each do |item|
          if item.requisite and not(data[item.name])
            raise OptionError.new("option \"%s\" is requisite" % [item.long])
          end
        end

        # apply validators
        @validators.each {|validator| validator.call(data)}
      end
    end

    # CommonOption provides common options for pione commands.
    module CommonOption
      extend OptionInterface

      define(:color) do |item|
        item.long = '--[no-]color'
        item.desc = 'turn on/off color mode'
        item.action = proc {|_, _, bool|
          Global.color_enabled = bool
          Sickill::Rainbow.enabled = bool
        }
      end

      define(:daemon) do |item|
        item.long = "--daemon"
        item.desc = "turn on daemon mode"
        item.default = false
        item.value = true
      end

      define(:debug) do |item|
        item.long = '--debug[=TYPE]'
        item.desc = "turn on debug mode about the type(system / rule_engine / ignored_exception / presence_notifier / communication)"
        item.action = proc {|cmd, _, type|
          Global.system_logger.level = :debug
          case type
          when "system", nil
            Global.debug_system = true
          when "rule_engine"
            Global.debug_rule_engine = true
          when "presence_notification"
            Global.debug_presence_notification = true
          when "communication"
            Global.debug_communication = true
          when "ignored_exception"
            Global.debug_ignored_exception = true
          else
            raise OptionError.new("option error: unknown debug type \"=%s\"" % type)
          end
        }
      end

      define(:features) do |item|
        item.long = '--features=FEATURES'
        item.desc = 'set features'
        item.action = proc {|cmd, option, features|
          begin
            # store features
            Global.features = features
          rescue Parslet::ParseFailed => e
            raise OptionError.new(
              "invalid feature expression \"%s\" is given for %s" % [features, cmd.command_name]
            )
          end
        }
      end

      define(:communication_address) do |item|
        item.long = "--communication-address=ADDRESS"
        item.desc = "set IP address for interprocess communication"
        item.action = proc {|_, _, address| Global.communication_address = address}
      end

      define(:parent_front) do |item|
        item.long = '--parent-front=URI'
        item.desc = 'set parent front URI'
        item.requisite = true
        item.action = proc do |cmd, option, uri|
          begin
            option[:parent_front] = DRbObject.new_with_uri(uri)
            timeout(1) {option[:parent_front].ping}
          rescue Exception => e
            raise HideableOptionError.new(
              "%s couldn't connect to parent front \"%s\": %s" % [cmd.command_name, uri, e.message]
            )
          end
        end
      end

      define(:presence_notification_address) do |item|
        item.long = "--presence-notification-address=255.255.255.255:%s" % Global.presence_port
        item.desc = "set the address for sending presence notifier"
        item.action = proc do |_, _, address|
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

      define(:task_worker) do |item|
        item.short = '-t N'
        item.long = '--task-worker=N'
        item.desc = 'set task worker number that this process creates'
        item.default = [Util::CPU.core_number - 1, 1].max
        item.value = proc {|n| n.to_i}
      end
    end
  end
end
