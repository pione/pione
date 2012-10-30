module Pione
  module TupleSpace
    class PresenceNotifier < PioneObject
      def self.inherited(subclass)
        subclass.instance_variable_set(:@monitor, Monitor.new)
      end

      def self.command_name
        @command_name
      end

      def self.set_command_name(name)
        @command_name = name
      end

      def self.notifier_uri
        @notifier_uri.call
      end

      def self.set_notifier_uri(proc)
        @notifier_uri = proc
      end

      # Creates the tuple space provider as new process.
      # @return [BasicFront]
      #   tuple space provider or receiver front
      def self.spawn
        user_message "create process for %s" % command_name
        # create provider process
        args = [
          command_name,
          '--presence-port', Global.presence_port.to_s,
          '--caller-front', Global.front.uri,
        ]
        args << "--relay-uri" << Global.relay_uri if Global.relay_uri
        args << "-d" if Pione.debug_mode?
        args << "--show-communication" if Global.show_communication
        pid = Process.spawn(*args)
        thread = Process.detach(pid)
        # wait that the provider starts up
        while thread.alive?
          begin
            front = DRbObject.new_with_uri(notifier_uri)
            break if front.uuid
          rescue
            sleep 0.1
          end
        end
        if thread.alive?
          return front
        else
          # failed to run pione-tuple-space-provider
          Process.abort("You cannot run %s." % command_name)
        end
      end

      # Returns the provider instance.
      # @return [PresenceNotifier]
      #   tuple space provider or receiver instance as druby object
      def self.instance
        @monitor.synchronize do
          # get provider reference
          begin
            front = DRbObject.new_with_uri(notifier_uri)
            front.uuid
            front
          rescue
            # create new provider
            self.spawn
          end.presence_notifier
        end
      end
    end
  end
end
