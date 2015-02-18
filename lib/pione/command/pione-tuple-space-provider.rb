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
        spawner.option_if(Global.debug_system, "--debug=system")
        spawner.option_if(Global.debug_ignored_exception, "--debug=ignored_exception")
        spawner.option_if(Global.debug_rule_engine, "--debug=rule_engine")
        spawner.option_if(Global.debug_communication, "--debug=communication")
        spawner.option_if(Global.debug_notification, "--debug=notification")

        # requisite options
        spawner.option("--parent-front", cmd.model[:front].uri)
        spawner.option("--communication-address", Global.communication_address)
        Global.notification_targets.each do |address|
          spawner.option("--notification-target", address)
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

        item << :tuple_space
        item << ProcessAction.connect_parent
      end

      setup(:tuple_space) do |item|
        item.process do
          model[:tuple_space] = TupleSpace::TupleSpaceServer.new()
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :start_agent
        item << :sleep
      end

      # Start agent's activity.
      execution(:start_agent) do |item|
        item.assign(:agent) do
          Agent::TupleSpaceProvider.start(model[:front].uri)
        end
      end

      # Sleep until agent is terminated.
      execution(:sleep) do |item|
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
          test(not(model[:agent].terminated?))

          model[:agent].terminate
          model[:agent].wait_until_terminated(nil)
        end
      end
    end
  end
end
