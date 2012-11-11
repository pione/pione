module Pione
  module Command
    # PioneTupleSpaceProvider is for +pione-tuple-space-provider+ command.
    class PioneTupleSpaceProvider < ChildProcess
      set_program_name("pione-tuple-space-provider") do
        parent_front = @no_parent_mode ? "nil" : @parent_front.uri
        "<front=%s, parent-front=%s>" % [Global.front.uri, parent_front]
      end

      set_program_message <<TXT
Runs tuple space provider process for sending tuple space presence
notifier. This command is launched by other processes like pione-client or
pione-relay normally, but you can force to start by calling with --no-parent
option.
TXT

      use_option_module CommandOption::TupleSpaceProviderOption

      attr_reader :tuple_space_provider

      def initialize
        super
        @parent_front = nil
        @notifier_addresses = []
      end

      # @api private
      def validate_options
        super

        # broadcast addresses
        @notifier_addresses.each do |uri|
          unless uri.scheme == "broadcast"
            abort("error: invalid broadcast address '%s'" % uri.to_s)
          end
        end
      end

      # @api private
      def create_front
        Pione::Front::TupleSpaceProviderFront.new(self)
      end

      # @api private
      def prepare
        super

        # setup notifier addresses
        unless @notifier_addresses.empty?
          Global.tuple_space_provider_broadcast_addresses = @notifier_addresses
        end

        # make tuple space provider
        @tuple_space_provider = TupleSpaceProvider.new
      end

      # @api private
      def start
        super

        # start provider activity
        @tuple_space_provider.start

        # set my URI to caller front as its provider
        unless @no_parent_mode
          @parent_front.set_tuple_space_provider(Global.front.uri)
        end

        # wait
        DRb.thread.join
      end

      # @api private
      def terminate
        begin
          puts "terminate %s" % program_name
          @tuple_space_provider.terminate
        rescue DRb::DRbConnError
        end
        super
        exit
      end
    end
  end
end
