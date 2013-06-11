module Pione
  module Command
    # OptionItem is an option item for PIONE command.
    class OptionItem < StructX
      member :name
      member :short
      member :long
      member :desc
      member :default
      member :value
      member :values
      member :action
      member :validator
    end

    # OptionInterface provides basic methods for option modules. All option
    # modules should be extended by this.
    module OptionInterface
      attr_reader :items

      # Define a new option for the command.
      #
      # @param args [Array]
      #   OptionParser arguments
      # @param b [Proc]
      #   option action
      # @return [void]
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

      # Install the option module.
      #
      # @param mod [Module]
      #   PIONE's option set modules
      # @return [void]
      def use(item_name)
        @items << CommonOption.send(item_name)
      end
    end

    # CommandOption is a class for holding option data set.
    class Option
      forward! :@option, :"[]", :"[]="

      # Creata a command option context.
      #
      # @param command_info [CommandInfo]
      #   command informations
      def initialize(program_name, banner)
        extend OptionInterface
        @program_name = program_name
        @banner = banner
        @option = {}
        @items = []
        @validators = []
      end

      def item(name)
        @items.find {|item| item.name == name}
      end

      # Parse the command options.
      #
      # @return [void]
      def parse(argv)
        OptionParser.new do |opt|
          # set banner
          opt.banner = "Usage: %s [options]" % @program_name
          opt.banner << "\n" + @banner if @banner

          # set version
          opt.program_name = @program_name
          opt.version = Pione::VERSION

          # default values
          @items.each {|item| @option[item.name] = item.default if item.default}

          # setup option parser
          @items.sort{|a,b| a.long <=> b.long}.each {|item| setup_item(opt, item)}
        end.parse!(argv)
      rescue OptionParser::InvalidOption => e
        e.args.each {|arg| $stderr.puts "Unknown option: %s" % arg }
        abort
      rescue OptionParser::MissingArgument => e
        abort(e.message)
      end

      def default(name, value)
        @option[name] = value
      end

      def validate(&b)
        @validators << b
      end

      # Check validness of the command options.
      #
      # @return [void]
      def check
        @validators.each do |validator|
          validator.call(@option)
        end
      end

      private

      SETUP_ITEM_LIST = [
        :setup_item_action,
        :setup_item_values,
        :setup_item_value,
        :setup_item_static_value
      ]

      # Setup the option item.
      def setup_item(opt, item)
        defs = [item.short, item.long, item.desc].compact
        SETUP_ITEM_LIST.find {|name| send(name, opt, item, defs)}
      end

      def setup_item_action(opt, item, defs)
        if item.action
          opt.on(*defs, Proc.new{|*args| self.instance_exec(@option, *args, &item.action)})
        end
      end

      def setup_item_values(opt, item, defs)
        if item.values.kind_of?(Proc)
          opt.on(*defs, Proc.new{|*args| @option[item.name] << self.instance_exec(*args, &item.values)})
        end
      end

      def setup_item_value(opt, item, defs)
        if item.value.kind_of?(Proc)
          opt.on(*defs, Proc.new{|*args| @option[item.name] = self.instance_exec(*args, &item.value)})
        end
      end

      def setup_item_static_value(opt, item, defs)
        if item.value
          opt.on(*defs, Proc.new{ @option[item.name] = item.value})
        end
      end
    end

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

      define(:features) do |item|
        item.long = '--features=FEATURES'
        item.desc = 'set features'
        item.value = proc {|features| features}
      end

      define(:my_ip_address) do |item|
        item.long = "--my-ip-address=ADDRESS"
        item.desc = "set my IP address"
        item.action = proc {|_, address| Global.my_ip_address = address}
      end

      define(:no_parent) do |item|
        item.long = '--no-parent'
        item.desc = 'turn on no parent mode'
        item.action = proc {|option| option[:no_parent_mode] = true}
      end

      define(:parent_front) do |item|
        item.long = '--parent-front=URI'
        item.desc = 'set parent front URI'
        item.action = proc do |option, uri|
          option[:parent_front] = DRbObject.new_with_uri(uri)
        end
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

      define(:task_worker) do |item|
        item.short = '-t N'
        item.long = '--task-worker=N'
        item.desc = 'set task worker number that this process creates'
        item.default = Agent::TaskWorker.default_number
        item.value = proc {|n| n.to_i}
      end
    end
  end
end
