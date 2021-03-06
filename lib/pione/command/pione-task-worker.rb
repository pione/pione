module Pione
  module Command
    # `PioneTaskWorker` is a command that runs pione task worker agents.
    class PioneTaskWorker < BasicCommand
      #
      # class methods
      #

      # Create a new process of `pione-task-worker` command.
      #
      # @param [Rootage::Model] model
      # @param [Hash] param
      # @option param [Array<String>] :features
      #   list of features that the task worker has
      # @option param [String] :tuple_space_id
      #   ID of tuple space that the task worker works in
      def self.spawn(model, param={})
        spawner = Spawner.new(model, "pione-task-worker")

        # debug options
        spawner.option_if(Global.debug_system, "--debug=system")
        spawner.option_if(Global.debug_ignored_exception, "--debug=ignored_exception")
        spawner.option_if(Global.debug_rule_engine, "--debug=rule_engine")
        spawner.option_if(Global.debug_communication, "--debug=communication")
        spawner.option_if(Global.debug_notification, "--debug=notification")

        # requisite options
        spawner.option_from(model, :front, "--parent-front", lambda {|val| val.uri})
        spawner.option_from(param, :tuple_space_id, "--tuple-space-id")
        spawner.option_from(param, :features, "--features")

        # others
        spawner.option("--color", Global.color_enabled)
        spawner.option("--file-cache-method", System::FileCache.cache_method.name)
        spawner.option("--file-sliding", Global.file_sliding)

        spawner.spawn # this method returns child front
      end

      #
      # informations
      #

      define(:toplevel, true)
      define(:name, "pione-task-worker")
      define(:desc, "process tasks")
      define(:front, Front::TaskWorkerFront)

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug
      option CommonOption.communication_address
      option CommonOption.parent_front
      option CommonOption.features
      option CommonOption.file_cache_method
      option CommonOption.file_sliding

      option(SessionOption.request_from)
      option(SessionOption.session_id)

      option(:tuple_space_id) do |item|
        item.type = :string
        item.long = '--tuple-space-id'
        item.arg  = 'UUID'
        item.desc = 'Tuple space ID that the worker joins'
        item.requisite = true
      end

      #
      # instance methods
      #

      attr_reader :agent
      attr_reader :tuple_space_server

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item.configure(:timeout => 15)

        item << ProcessAction.connect_parent
        item << :tuple_space
        item << :task_worker_agent
        item << :job_terminator
        item << :base_location
      end

      setup(:tuple_space) do |item|
        item.desc = "Get a tuple space from parent"

        item.assign(:tuple_space) do
          model[:parent_front].get_tuple_space(model[:tuple_space_id])
        end

        item.process do
          test(not(model[:tuple_space]))

          arg = {name: cmd.name, id: option[:tuple_space_id]}
          cmd.abort('"%{name}" cannot get the tuple space "%{id}".' % arg)
        end

        item.process do
          if Util.error?(:timeout => 3) {model[:tuple_space].uuid}
            cmd.abort('"%{name}" cannot connect to tuple space.' % {name: cmd.name})
          end
        end

        item.assign(:request_from) {model[:tuple_space].attribute("request_from")}
        item.assign(:session_id) {model[:tuple_space].attribute("session_id")}
      end

      setup(:task_worker_agent) do |item|
        item.desc = "Create a task worker agent"

        item.assign(:task_worker_agent) do
          Agent::TaskWorker.new(model[:tuple_space], Global.expressional_features)
        end

        item.exception(Agent::TupleSpaceError) do |e|
          cmd.abort(e)
        end
      end

      setup(:base_location) do |item|
        item.desc = "Get a base location"

        item.assign(:base_location) do
          model[:tuple_space].base_location
        end

        item.process do
          # enable Dropbox location
          if model[:base_location].is_a?(Location::DropboxLocation)
            begin
              Location::DropboxLocation.enable(model[:tuple_space])
            rescue Location::DropboxLocationUnavailable => e
              arg = {addr: model[:base_location].address}
              cmd.abort('Base location "%{addr}" is on Dropbox, but it is not ready.' % arg)
            end
          end
        end
      end

      setup(:job_terminator) do |item|
        item.desc = "Create a job terminator and setup the action"

        item.assign(:job_terminator) do
          Agent::JobTerminator.new(model[:tuple_space]) do |status|
            if status.error?
              cmd.abort('"%s" catched the error: %s' % [cmd.name, status.message])
            else
              cmd.terminate
            end
          end
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :job_terminator
        item << :task_worker_agent

        item.exception(DRb::DRbConnError) do |e|
          Log::Debug.system do
            "%s goes termination phase because the exception was catched: %s" % [cmd.name, e.message]
          end
          cmd.terminate
        end
      end

      execution(:job_terminator) do |item|
        item.desc = "Start the job terminator"

        item.process do
          model[:job_terminator].start
        end
      end

      execution(:task_worker_agent) do |item|
        item.desc = "Start task worker activity and wait the termination"

        item.process do
          model[:task_worker_agent].start
          model[:task_worker_agent].wait_until_terminated(nil)
        end
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |item|
        item.configure(:timeout => 10)
        item << ProcessAction.disconnect_parent
        item << :job_terminator
        item << :task_worker_agent
      end

      termination(:job_terminator) do |item|
        item.desc = "Terminate job terminator agent"

        item.condition do
          test(model[:job_terminator])
          test(not(model[:job_terminator].terminated?))
        end

        item.process do
          model[:job_terminator].terminate
        end
      end

      termination(:task_worker_agent) do |item|
        item.desc = "Terminate task worker agent"

        item.condition do
          test(model[:task_worker_agent])
          test(not(model[:task_worker_agent].terminated?))
        end

        item.process do
          model[:task_worker_agent].terminate
          model[:task_worker_agent].wait_until_terminated(nil)
        end
      end
    end
  end
end
