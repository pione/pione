module Pione
  module Command
    # `PioneTupleSpaceBroker` is for `pione-tuple-space-broker` command.
    class PioneTupleSpaceBroker < BasicCommand
      #
      # informations
      #

      define(:toplevel, true)
      define(:name, "pione-tuple-space-broker")
      define(:desc, "run tuple space provider agent")
      define(:front, Pione::Front::TupleSpaceBrokerFront)

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
        item << :tuple_space_manager
      end

      setup(:tuple_space_manager) do |item|
        item.process do
          model[:tuple_space_manager] = TupleSpace::Manager.new(self)
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :banner
        seq << :sleep
      end

      execution(:banner) do |item|
        item.process do
          Log::SystemLog.info("Start tuple space broker.")
        end
      end

      execution(:sleep) do |item|
        item.process { sleep }
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |seq|
        seq.configure(:timeout => 5)

        seq << ProcessAction.terminate_children
      end
    end
  end
end
