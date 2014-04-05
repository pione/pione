module Pione
  module Command
    # `PioneTupleSpaceProvider` is for `pione-tuple-space-provider` command.
    class PioneTupleSpaceProvider < BasicCommand
      #
      # class methods
      #

      # Create a new process of tuple space provider command.
      def self.spawn(cmd)
        spawner = Spawner.new(cmd.model, "pione-tuple-space-provider")

        # debug options
        spawner.option("--debug=system") if Global.debug_system
        spawner.option("--debug=ignored_exception") if Global.debug_ignored_exception
        spawner.option("--debug=rule_engine") if Global.debug_rule_engine
        spawner.option("--debug=communication") if Global.debug_communication
        spawner.option("--debug=notification") if Global.debug_notification

        # requisite options
        spawner.option("--parent-front", cmd.model[:front].uri.to_s)
        spawner.option("--communication-address", Global.communication_address.to_s)
        Global.notification_targets.each do |address|
          spawner.option("--notification-target", address.to_s)
        end

        # optionals
        spawner.option("--color", Global.color_enabled)

        spawner.spawn
      end

      #
      # informations
      #

      define(:toplevel, true)
      define(:name, "pione-tuple-space-provider")
      define(:desc, "run tuple space provider agent")
      define(:front, Pione::Front::TupleSpaceProviderFront)

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug
      option CommonOption.communication_address
      option CommonOption.parent_front
      option NotificationOption.notification_targets

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item.configure(:timeout => 5)

        item << ProcessAction.connect_parent
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :start_agent
        item << :wait_agent
      end

      execution(:start_agent) do |item|
        item.desc = "Start an agent activity"

        item.assign(:agent) do
          Agent::TupleSpaceProvider.start(model[:front].uri)
        end
      end

      execution(:wait_agent) do |item|
        item.desc = "Wait agent to terminate"

        item.process do
          model[:agent].wait_until_terminated(nil)
        end
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |seq|
        seq.configure(:timeout => 5)

        seq << :agent
        seq << ProcessAction.disconnect_parent
      end

      termination(:agent) do |item|
        item.desc = "Terminate the agent"

        item.process do
          test(model[:agent])
          test(model[:agent].terminated?)

          model[:agent].terminate
          model[:agent].wait_until_terminated(nil)
        end
      end
    end
  end
end
