module Pione
  module Command
    # `PioneTaskWorkerBroker` is a command that starts activity of task worker
    # broker agent. This command will spawn `pione-task-worker`.
    class PioneTaskWorkerBroker < BasicCommand
      #
      # informations
      #

      define(:toplevel, true)
      define(:name, "pione-task-worker-broker")
      define(:desc, "run task worker broker agent to launch task workers")
      define(:front, Front::TaskWorkerBrokerFront)
      define(:model, Model::TaskWorkerBrokerModel)
      define(:notification_recipient, Notification::TaskWorkerBrokerRecipient) {|cmd, model|
        [model, Global.notification_listener]
      }

      #
      # options
      #

      option(CommonOption.color)
      option(CommonOption.debug)
      option(CommonOption.features)
      option(CommonOption.communication_address)
      option(CommonOption.task_worker_size) do |item|
        item.type = :positive_integer
      end
      option CommonOption.file_cache_method
      option CommonOption.no_file_sliding

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item.configure(:timeout => 10)
        item << :task_worker_broker_agent
      end

      setup(:task_worker_broker_agent) do |item|
        item.desc = "Create a task worker broker agent"

        item.assign(:task_worker_broker_agent) do
          Agent::TaskWorkerBroker.new(model)
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :task_worker_broker_agent
      end

      execution(:task_worker_broker_agent) do |item|
        item.desc = "Start agent activity of task worker broker"

        item.process do
          model[:task_worker_broker_agent].start!
        end
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |item|
        item.configure(:timeout => 15)
        item << ProcessAction.terminate_children
        item << :task_worker_broker_agent
      end

      termination(:task_worker_broker_agent) do |item|
        item.desc = "Terminate the agent"

        item.process do
          test(model[:task_worker_broker_agent])
          test(not(model[:task_worker_broker_agent].terminated?))

          model[:task_worker_broker_agent].terminate
        end
      end
    end
  end
end
