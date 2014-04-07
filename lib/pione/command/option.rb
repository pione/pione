module Pione
  module Command
    # CommonOption provides common options for almost pione commands.
    module CommonOption
      extend Rootage::OptionCollection

      define(:color) do |item|
        item.type = :boolean
        item.long = '--color'
        item.arg  = 'BOOLEAN'
        item.desc = 'Turn on/off color mode'

        item.process {|val| Global.color_enabled = val}
      end

      define(:debug) do |item|
        item.type    = :string
        item.range   =
          ["system", "rule_engine", "ignored_exception", "notification", "communication"]
        item.long    = '--debug'
        item.arg     = '[TYPE]'
        item.desc    = "Turn on debug mode about the type"
        item.default = "system"

        item.process do |type|
          Global.system_logger.level = :debug
          case type
          when "system", nil
            Global.debug_system = true
          when "rule_engine"
            Global.debug_rule_engine = true
          when "notification"
            Global.debug_notification = true
          when "communication"
            Global.debug_communication = true
          when "ignored_exception"
            Global.debug_ignored_exception = true
          else
            raise OptionError.new(cmd, 'Unknown debug type "%s"' % type)
          end
        end
      end

      define(:features) do |item|
        item.type = :string
        item.long = '--features'
        item.arg  = 'FEATURES'
        item.desc = 'Set features'

        item.process {|val| Global.features = val}

        item.exception(Parslet::ParseFailed) do |e, val|
          arg = {features: val, reason: e.message}
          raise OptionError.new(
            cmd, 'The feature expression "%{features}" is invalid: %{reason}' % arg
          )
        end
      end

      define(:communication_address) do |item|
        item.type = :uri
        item.long = "--communication-address"
        item.arg  = 'URI'
        item.desc = "Set the IP address for interprocess communication"

        item.process {|address| Global.communication_address = address}
      end

      define(:parent_front) do |item|
        item.type = :uri
        item.long = '--parent-front'
        item.arg  = 'URI'
        item.desc = 'set parent front URI'

        item.assign {|uri| DRbObject.new_with_uri(uri.to_s)}

        item.process do |uri|
          timeout(1) {model[:parent_front].ping}
        end

        item.exception(Exception) do |e, uri|
          arg = {name: cmd.name, uri: uri.to_s, reason: e.message}
          raise HideableOptionError.new(
            cmd, '"%{name}" has failed to connect to parent front "%{uri}": %{reason}' % arg
          )
        end
      end

      define(:task_worker_size) do |item|
        item.type  = :integer
        item.short = '-t'
        item.long  = '--task-worker-size'
        item.arg   = 'N'
        item.desc  = 'Set task worker size that this process creates'
        item.init  = [Util::CPU.core_number - 1, 1].max
      end

      define(:domain_dump_location) do |item|
        item.type = :location
        item.long = '--domain-dump'
        item.arg  = 'LOCATION'
        item.desc = 'Import the domain dump file'

        item.process do |location|
          unless location.exist?
            raise OptionError.new(
              cmd, 'The location doesn\'t exist: %{location}' % {location: location}
            )
          end
        end

        item.assign(:domain_dump_location) do |location|
          test(location.file?)
          location
        end

        item.assign(:domain_dump_location) do |location|
          test(location.directory?)

          # find default domain dump file
          _location = location + System::DomainDump::FILENAME
          if _location.exist?
            _location
          else
            raise OptionError.new(
              cmd, 'The location doesn\'t exist: %{location}' % {location: _location}
            )
          end
        end
      end

      define(:file_cache_method) do |item|
        item.long = '--file-cache-method NAME'
        item.desc = 'use NAME as a file cache method'
        item.action = proc do |command_name, option, name|
          System::FileCache.set_cache_method(name.to_sym)
        end
      end

      define(:no_file_sliding) do |item|
        item.long = '--no-file-sliding'
        item.desc = 'Disable to slide files in file server'
        item.action = proc do |command_name, option|
          Global.no_file_sliding = true
        end
      end
    end

    # `NotificationOption` provides for notification options.
    module NotificationOption
      extend Rootage::OptionCollection

      define(:notification_targets) do |item|
        item.type = :string
        item.long = '--notification-target'
        item.arg  = 'URI'
        item.desc = 'Target address that notifications are sent to'
        item.init = Global.notification_targets

        item.assign(:__defined_notification_targets__) do |address|
          test(not(model[:__defined_notification_targets__]))

          Global.notification_targets.clear
          true
        end

        item.process do |address|
          uri = Notification::Address.target_address_to_uri(address.strip)
          if ["pnb", "pnm", "pnu"].include?(uri.scheme)
            Global.notification_targets << uri
          else
            cmd.abort('"%s" seems not to be a notification address.' % address)
          end
        end
      end

      define(:notification_receivers) do |item|
        item.type = :string
        item.long = "--notification-receiver"
        item.arg  = "URI"
        item.desc = "Receiver address that notifications are received at"
        item.init = Global.notification_receivers

        # clear default notification address
        item.assign(:__defined_notification_receivers__) do |address|
          test(not(model[:__defined_notification_receivers__]))

          Global.notification_receivers.clear
          true
        end

        # check the address and append it to receivers
        item.process do |address|
          uri = Notification::Address.receiver_address_to_uri(address.strip)
          if ["pnb", "pnm", "pnu"].include?(uri.scheme)
            Global.notification_receivers << uri
          else
            cmd.abort('"%s" seems not to be a notification address.' % address)
          end
        end
      end
    end
  end
end
