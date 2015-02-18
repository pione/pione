module Pione
  module Command
    # PioneClient is a command to request processing.
    class PioneClient < BasicCommand
      include TupleSpace::TupleSpaceInterface

      #
      # basic informations
      #

      define(:toplevel, true)
      define(:name, "pione-client")
      define(:desc, "Process PIONE document")
      define(:front, Front::ClientFront)

      #
      # arguments
      #

      argument(:location) do |item|
        item.type     = :location
        item.key_name = :package_location
        item.desc     = "package location"
        item.missing  = "There are no PIONE documents or packages."
      end

      #
      # options
      #

      option_pre(:prepare_model) do |item|
        item.desc = "Prepare model"
        item.assign(:params) {Lang::ParameterSetSequence.new}
      end

      option(CommonOption.debug)
      option(CommonOption.color)
      option(CommonOption.communication_address)
      option(CommonOption.task_worker_size)
      option(CommonOption.parent_front) do |item|
        item.requisite = false
      end
      option(CommonOption.features) do |item|
        item.default = Global.features + "& ^Interactive"
      end
      option(CommonOption.file_cache_method)
      option(CommonOption.file_sliding)

      option(NotificationOption.notification_targets)
      option(NotificationOption.notification_receivers)

      option(SessionOption.request_from)
      option(SessionOption.session_id)

      option(:input_location) do |item|
        item.type  = :location
        item.short = '-i'
        item.long  = '--input'
        item.arg   = 'LOCATION'
        item.desc  = 'Set input directory'
      end

      option(:base_location) do |item|
        item.type  = :location
        item.short = '-b'
        item.long  = '--base'
        item.arg   = 'LOCATION'
        item.desc  = 'Set process base location'
        item.init  = "local:./process/"

        item.process do |location|
          model[:base_location] = location
          if location.scheme == "myftp"
            model[:myftp] = URI.parse(uri).normalize
          end
        end

        item.exception(ArgumentError) do |e, val|
          raise OptionError.new(cmd, "base location '%s' is bad in %s" % [uri, cmd.name])
        end
      end

      option(:stream) do |item|
        item.type    = :boolean
        item.long    = '--stream'
        item.arg     = '[BOOLEAN]'
        item.desc    = 'Turn on/off stream mode'
        item.init    = false
        item.default = true
      end

      option(:request_task_worker) do |item|
        item.type = :integer
        item.long = '--request-task-worker'
        item.arg  = 'N'
        item.desc = 'Set request number of task workers'
        item.init = 1
      end

      option(:params) do |item|
        item.type = :param_set
        item.long = '--params="{Var:1,...}"'
        item.desc = "Set user parameters"

        item.assign do |params|
          model[:params].merge(params)
        end

        item.exception(Parslet::ParseFailed) do |e, str|
          arg = {str: str, name: cmd.name, reason: e.message}
          raise OptionError.new(cmd, 'Invalid parameters "%{str}" in %{name}: %{reason}' % arg)
        end
      end

      option(:stand_alone) do |item|
        item.type    = :boolean
        item.long    = '--stand-alone'
        item.desc    = 'Turn on stand alone mode'
        item.init    = false
        item.default = true

        item.process do |val|
          model[:without_tuple_space_provider] = val
        end
      end

      option(:dry_run) do |item|
        item.long    = '--dry-run'
        item.desc    = 'Turn on dry run mode'
        item.type    = :boolean
        item.init    = false
        item.default = true
      end

      option(:rehearse) do |item|
        item.type = :string
        item.long = '--rehearse'
        item.arg  = '[SCENARIO]'
        item.desc = 'rehearse the scenario'

        item.assign {|val| (not(val.nil?) and val.size != 0) ? val : :anything}
      end

      option(:timeout) do |item|
        item.type = :positive_integer
        item.long = '--timeout'
        item.arg  = 'SEC'
        item.desc = 'timeout processing after SEC'
      end

      option(:client_ui) do |item|
        item.type = :string
        item.long = "--client-ui"
        item.arg  = "TYPE"
        item.desc = "Type of the client's user interface"
      end

      option(:delegate_tuple_space) do |item|
        item.type    = :boolean
        item.long    = '--delegate-tuple-space'
        item.desc    = 'Delegate tuple space to broker'
        item.init    = false
        item.default = true
      end

      option_post(:validate_task_worker_size) do |item|
        item.desc = "Validate task worker size"
        item.process do
          test(model[:task_worker_size] == 0)
          test(model[:stand_alone])
          raise Rootage::OptionError.new(cmd, "option error: invalid task worker size '%s'" % model[:task_worker])
        end
      end

      option_post(:stream_location) do |item|
        item.desc = "Validate stream location"
        item.process do
          test(model[:stream])
          test(model[:input_location].nil?)
          raise Rootage::OptionError.new(cmd, "option error: no input URI on stream mode")
        end
      end

      #
      # command lifecycle: setup phase
      #

      # setup_phase :timeout => 20 # because of setup for dropbox...
      phase(:setup) do |seq|
        seq << ProcessAction.connect_parent
        seq << :spawner_thread_group
        seq << :ftp_server
        seq << :tuple_space_provider
        seq << :tuple_space
        seq << :base_location
        seq << :lang_environment
        seq << :package
        seq << :scenario
      end

      setup(:spawner_thread_group) do |item|
        item.desc = "Make a spawner thread group"

        item.assign(:spawner_threads) {ThreadGroup.new}
      end

      setup(:ftp_server) do |item|
        item.desc = "Setup FTP server with the URI"

        item.process do
          test(model[:myftp])

          uri = model[:myftp]
          location = Location[uri.path]
          location.path.mkdir unless location.exist?
          if uri.userinfo
            Util::FTPServer.auth_info = Util::FTPAuthInfo.new(uri.user, uri.password)
          end
          if uri.port
            Util::FTPServer.port = myftp.port
          end
          Util::FTPServer.start(Util::FTPLocalFS.new(location))
        end
      end

      # Spawn a tuple space provider
      setup(:tuple_space_provider_spawner) do |item|
        item.process do
          spawner = Command::PioneTupleSpaceProvider.spawn(cmd)
          model[:tuple_space_provider_spawner] = spawner
          model[:tuple_space_provider] = spawner.child_front

          spawner.when_terminated do
            if cmd.current_phase == :setup or cmd.current_phase == :execution
              cmd.abort("%s is terminated because child tuple space provider is maybe dead." % cmd.name)
            end
          end
        end

        item.exception(SpawnError) do |e|
          if cmd.current_phase == :termination
            Log::Debug.system(e.message)
          else
            cmd.abort(e)
          end
        end
      end

      # Spawn a tuple space provider.
      setup(:tuple_space_provider) do |item|
        item.process do
          if model[:delegate_tuple_space]
            # get tuple space from tuple space broker
            begin
              Log::SystemLog.info("Find tuple space broker...")
              Timeout.timeout(5) do
                message = Notification::Message.new("CLIENT", "FIND_TUPLE_SPACE_BROKER", {"front" => model[:front].uri})
                Notification::Transmitter.transmit(message)
                model[:thread] = Thread.current
                Thread.stop
              end
              Log::SystemLog.info('Tuple space broker "%s" has found.' % model[:tuple_space_broker_front_uri])
            rescue Timeout::Error
              cmd.abort("Tuple space broker has not found.")
            end
          else
            # create tuple space by myself
            cmd.phase(:setup).find_item(:tuple_space_provider_spawner).execute(cmd)
            model[:tuple_space] = model[:tuple_space_provider].tuple_space()
          end
        end
      end

      setup(:tuple_space) do |item|
        item.desc = "Make a tuple space"

        item.process do
          model[:front].set_tuple_space(model[:tuple_space])

          # write tuples
          resource = model[:request_task_worker] || 1
          model[:tuple_space].write(TupleSpace::TaskWorkerResourceTuple.new(number: resource))
          model[:tuple_space].write(TupleSpace::ProcessInfoTuple.new('standalone', 'Standalone'))
          model[:tuple_space].write(TupleSpace::DryRunTuple.new(model[:dry_run]))

          if model[:request_from]
            model[:tuple_space].write(TupleSpace::AttributeTuple.new("request_from", model[:request_from]))
          end

          if model[:session_id]
            model[:tuple_space].write(TupleSpace::AttributeTuple.new("session_id", model[:session_id]))
          end

          if model[:client_ui]
            model[:tuple_space].write(TupleSpace::AttributeTuple.new("client_ui", model[:client_ui]))
          else
            model[:tuple_space].write(TupleSpace::AttributeTuple.new("client_ui", "GUI"))
          end
        end
      end

      setup(:base_location) do |item|
        item.desc = "Setup base location"

        # setup location
        item.process do
          case model[:base_location]
          when Location::LocalLocation
            model[:base_location] = Location[model[:base_location].path.expand_path]
            model[:base_location].path.mkpath
          when Location::DropboxLocation
            Location::DropboxLocation.setup_for_cui_client(tuple_space_server)
          end
        end

        # mkdir
        item.process do
          test(not(model[:base_location].exist?))
          model[:base_location].mkdir
        end

        # set base location into tuple space
        item.process do
          model[:tuple_space].set_base_location(model[:base_location])
        end
      end

      setup(:lang_environment) do |item|
        item.desc = "Make an environment"

        item.assign(:env) do
          Lang::Environment.new
        end
      end

      # This setups package sharing and secnario handling also.
      setup(:package) do |item|
        item.desc = "Read a PIONE package"

        # read package
        item.assign(:package_handler) do
          Package::PackageReader.read(model[:package_location])
        end

        # merge the package into environment
        item.assign(:env) do
          model[:package_handler].eval(model[:env])
        end

        # upload the package
        item.process do
          model[:package_handler].upload(model[:base_location] + "package")
        end

        item.exception(Package::InvalidPackage) do |e|
          cmd.abort("Package error: " + e.message)
        end

        item.exception(Lang::ParserError) do |e|
          cmd.abort("Pione syntax error: " + e.message)
        end

        item.exception(Lang::LangError) do |e|
          cmd.abort("Pione language error: %s(%s)" % [e.message, e.class.name])
        end
      end

      setup(:scenario) do |item|
        item.desc = "Read a scenario"

        item.condition do
          test(model[:rehearse])
          test(not(model[:package_handler].info.scenarios.empty?))
        end

        item.assign(:scenario_handler) do
          model[:package_handler].find_scenario(model[:rehearse])
        end

        item.assign(:input_location) do
          if model[:scenario_handler]
            model[:scenario_handler].input
          else
            cmd.abort("the scenario not found: %s" % model[:rehearse])
          end
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :job_terminator
        seq << :messenger
        seq << :logger
        seq << :input_generator
        seq << :task_worker
        seq << :job_manager
        seq << :check_rehearsal_result
      end

      execution(:job_terminator) do |item|
        item.desc = "Start a job terminator"

        item.assign(:job_terminator) do
          Agent::JobTerminator.start(model[:tuple_space]) do |status|
            if status.error?
              cmd.abort("pione-client catched the error: %s" % status.message, exception: status.exception)
            else
              cmd.terminate
            end
          end
        end
      end

      execution(:messenger) do |item|
        item.desc = "Start a messenger agent"

        item.assign(:messenger) do
          # select receiver
          if model[:parent_front] and model[:parent_front][:message_log_receiver]
            # delegate parent's receiver
            receiver = model[:parent_front][:message_log_receiver]
          else
            # CUI receiver
            receiver = Log::CUIMessageLogReceiver.new
          end

          Agent::Messenger.new(model[:tuple_space], receiver, model[:session_id]).start
        end
      end

      # Launch a logger agent.
      execution(:logger) do |item|
        item.desc = "Start a logger agent"

        item.assign(:logger) do
          Agent::Logger.start(model[:tuple_space], model[:base_location])
        end
      end

      execution(:input_generator) do |item|
        item.desc = "Start an input generator agent"

        item.assign(:input_generator) do
          Agent::InputGenerator.start(
            model[:tuple_space], :dir, model[:input_location], model[:stream]
          )
        end
      end

      # Spawn a task worker command. This is used from `task_worker` action.
      execution(:task_worker_spawner) do |item|
        item.desc = "Spawn a task worker"

        item.process do
          param = {
            :features => Global.features,
            :tuple_space_id => model[:tuple_space].uuid
          }

          model[:task_worker_spawners] << Command::PioneTaskWorker.spawn(model, param)
        end

        item.exception(SpawnError) do |e|
          if cmd.current_phase == :termination
            # ignore the exception if the command is terminating
            Log::Debug.system(e.message)
          else
            cmd.abort(e)
          end
        end
      end

      # Launch task worker agents in the client side. If the client is
      # stand-alone mode, they are in this thread. Otherwise, in other OS
      # process.
      execution(:task_worker) do |item|
        item.desc = "Start task workers"

        item.assign(:task_workers) {Array.new}

        # stand-alone mode
        item.process do
          test(model[:stand_alone])

          # start task worker agents in this command
          model[:task_worker_size].times do
            model[:task_workers] << Agent::TaskWorker.start(
              model[:tuple_space], Global.expressional_features, model[:env]
            )
          end
        end

        # distribution mode
        item.process do
          test(not(model[:stand_alone]))

          model[:task_worker_spawners] = []

          # spawn task worker commands
          model[:task_worker_size].times do
            # we don't wait workers start up because of performance
            thread = Thread.new do
              cmd.phase(:execution).find_item(:task_worker_spawner).execute(cmd)
            end
            model[:spawner_threads].add(thread)
          end
        end
      end

      execution(:job_manager) do |item|
        item.desc = "Start a job manager agent"

        item.assign(:job_manager) do
          param_set = Lang::ParameterSet.new

          # from option
          if model[:params] and not(model[:params].pieces.empty?)
            param_set = model[:params].pieces.first
          end

          # from scenario
          if not(model[:scenario_handler].nil?) and model[:scenario_handler].info.textual_param_sets
            param_set = Util.parse_param_set(model[:scenario_handler].info.textual_param_sets).pieces.first
          end

          # start
          Agent::JobManager.start(
            model[:tuple_space], model[:env], model[:package_handler], param_set, model[:stream]
          )
        end

        item.process do
          Timeout::timeout(model[:timeout]) do
            model[:job_manager].wait_until_terminated(nil)
          end
        end

        item.exception(Agent::JobError) do |e|
          cmd.abort(e)
        end

        item.exception(Timeout::Error) do |e|
          cmd.abort("Job timed out after %{number} sec." % {number: model[:timeout]})
        end
      end

      execution(:check_rehearsal_result) do |item|
        item.desc = "Check rehearsal result"

        item.process do
          test(model[:rehearse])
          test(not(model[:package_handler].info.scenarios.empty?))

          pscenario = test(model[:package_handler].find_scenario(model[:rehearse]))

          errors = pscenario.validate(model[:base_location] + "output")
          if errors.empty?
            Log::SystemLog.info "Rehearsal Result: Succeeded"
          else
            puts "Rehearsal Result: Failed"
            errors.each {|error| puts "- %s" % error.to_s}
            cmd.exit_status = false
          end
        end
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |seq|
        seq.configure(:timeout => 10)

        seq << :spawner_thread
        seq << :job_manager
        seq << :job_terminator
        seq << :task_worker
        seq << :input_generator
        seq << :logger
        seq << :messenger
        seq << :tuple_space
        seq << :kill_task_worker_processes
        seq << ProcessAction.terminate_children
        seq << ProcessAction.disconnect_parent
      end

      # This action is required for the case that the requested job reaches end
      # before task workers finish to be spawned.
      termination(:spawner_thread) do |item|
        item.desc = "Terminate spawner threads"

        item.process do
          if model[:spawner_threads]
            model[:spawner_threads].list.each {|thread| thread.kill}
          end
        end
      end

      # Terminate job manager agent. Be careful that main thread of
      # `pione-client` command waits to stop the job manager's chain thread, so
      # pione-client cannot terminate until the thread terminated.
      termination(:job_manager) do |item|
        item.process do
          test(model[:job_manager])
          test(not(model[:job_manager].terminated?))

          model[:job_manager].terminate
        end
      end

      termination(:job_terminator) do |item|
        item.desc = "Terminate job terminator agent"

        item.process do
          test(model[:job_terminator])
          test(not(model[:job_terminator].terminated?))

          model[:job_terminator].terminate
        end
      end

      termination(:task_worker) do |item|
        item.desc = "Terminate task worker agents"

        item.process do
          test(model[:stand_alone])
          test(model[:task_workers])

          model[:task_workers].each {|task_worker| task_worker.terminate}
        end
      end

      termination(:input_generator) do |item|
        item.desc = "Terminate input generator agent"

        item.process do
          test(model[:input_generator])
          test(not(model[:input_generator].terminated?))

          model[:input_generator].terminate
        end
      end

      termination(:logger) do |item|
        item.desc = "Terminate logger agent"

        item.process do
          test(model[:logger])
          test(not(model[:logger].terminated?))

          model[:logger].terminate
        end
      end

      termination(:messenger) do |item|
        item.desc = "Terminate messenger agent"

        item.process do
          test(model[:messenger])
          test(not(model[:messenger].terminated?))

          model[:messenger].terminate
        end
      end

      termination(:tuple_space) do |item|
        item.desc = "Terminate tuple space agent"

        item.process do
          test(model[:tuple_space])

          model[:tuple_space].terminate
        end
      end

      # Kill task worker processes.
      termination(:kill_task_worker_processes) do |item|
        item.process do
          unless model[:task_worker_spawners].nil?
            model[:task_worker_spawners].each do |child|
              Util.ignore_exception {Process.kill(:TERM, child.pid)}
            end
          end
        end
      end
    end
  end
end
