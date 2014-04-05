module Pione
  module Command
    # `PioneNotificationListener` is a command that listens notification
    # messages and sends it to registered receivers.
    class PioneNotificationListener < BasicCommand
      #
      # informations
      #

      define(:toplevel, true)
      define(:name, "pione-notification-listener")
      define(:desc, "listen notification messages")
      define(:front, Front::NotificationListenerFront)
      define(:model, Model::NotificationListenerModel)

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug
      option CommonOption.communication_address
      option NotificationOption.notification_receivers

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item << :model
      end

      setup(:model) do |item|
        item.desc = "Initialize the command model"

        item.assign(:notification_listener_agents) {Array.new}
        item.assign(:threads) {ThreadsWait.new}
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :notification_listener_agents
      end

      execution(:notification_listener_agents) do |item|
        item.desc = "Create notification listener agents"

        # launch a listener agent
        item.process do
          Global.notification_receivers.each do |address|
            agent = Agent::NotificationListener.start(model, address)
            model[:notification_listener_agents] << agent
            model[:threads].join_nowait(
              Thread.new {agent.wait_until_terminated(nil)}
            )
          end
        end

        # wait agents
        item.process do
          model[:threads].all_waits
        end

        item.exception(Agent::ConnectionError) do
          Log::SystemLog.fatal('`pione-notification-listener` is terminated because pione-borker may be dead.')
          cmd.terminate
        end
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |item|
        item.configure(:timeout => 5)
        item << :notification_listener_agents
      end

      termination(:notification_listener_agents) do |item|
        item.desc = "Terminate notification listener agent"

        item.process do
          model[:notification_listener_agents].each do |agent|
            if not(agent.terminated?)
              agent.terminate
            end
          end
        end
      end
    end
  end
end
