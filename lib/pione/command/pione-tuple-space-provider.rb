module Pione
  module Command
    # PioneTupleSpaceProvider is for +pione-tuple-space-provider+ command.
    class PioneTupleSpaceProvider < ChildProcess
      define_info do
        set_name "pione-tuple-space-provider"
        set_tail {|cmd|
          front_uri = begin Global.front.uri rescue "failed" end
          parent_front = begin cmd.option[:no_parent_mode] ? "nil" : cmd.option[:parent_front].uri rescue "failed" end
          "{Front: %s, ParentFront: %s}" % [front_uri, parent_front]
        }
        set_banner <<TXT
Run tuple space provider process for sending tuple space presence notifier. This
command is launched by other processes like pione-client or pione-relay
normally, but you can force to start by calling with --no-parent option.
TXT
      end

      define_option do
        use Option::CommonOption.debug
        use Option::CommonOption.show_communication
        use Option::CommonOption.color
        use Option::CommonOption.presence_notification_address
        use Option::CommonOption.my_ip_address
        use Option::CommonOption.show_presence_notifier
        use Option::ChildProcessOption.parent_front
        use Option::ChildProcessOption.no_parent
      end

      attr_reader :tuple_space_provider

      # @api private
      def create_front
        Pione::Front::TupleSpaceProviderFront.new(self)
      end

      prepare do
        # make tuple space provider
        @tuple_space_provider = TupleSpaceProvider.new
      end

      start do
        # start provider activity
        @tuple_space_provider.start

        begin
          # set my URI to caller front as its provider
          unless option[:no_parent_mode]
            option[:parent_front].set_tuple_space_provider(Global.front.uri)
          end

          # wait
          DRb.thread.join
        rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
          # ignore
        end
      end

      terminate do
        Global.monitor.synchronize do
          begin
            @tuple_space_provider.terminate
          rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
            abort
          end
        end
      end
    end
  end
end
