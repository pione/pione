module Pione
  module Command
    # PioneClient is a command to request processing.
    class PioneClient < BasicCommand
      include TupleSpace::TupleSpaceInterface

      #
      # basic informations
      #

      toplevel true
      command_name("pione-client") {|cmd| "front: %s" % Global.front.uri}
      command_banner "Process PIONE document."
      command_front Front::ClientFront

      #
      # options
      #

      use_option :debug
      use_option :color
      use_option :communication_address
      use_option :notification_address
      use_option :task_worker
      use_option :features
      use_option :parent_front, :requisite => false

      define_option(:input_location) do |item|
        item.short = '-i LOCATION'
        item.long = '--input=LOCATION'
        item.desc = 'set input directory'
        item.value = proc do |uri|
          begin
            Location[uri]
          rescue ArgumentError
            raise OptionError.new("input location '%s' is bad" % uri)
          end
        end
      end

      define_option(:output_location) do |item|
        item.short = '-o LOCATION'
        item.long = '--output=LOCATION'
        item.desc = 'set output directory'
        item.default = Location["local:./output/"]
        item.action = proc do |cmd, option, uri|
          begin
            option[:output_location] = Location[uri]
            if URI.parse(uri).scheme == "myftp"
              option[:myftp] = URI.parse(uri).normalize
            end
          rescue ArgumentError
            raise OptionError.new("output location '%s' is bad in %s" % [uri, cmd.command_name])
          end
        end
      end

      define_option(:stream) do |item|
        item.long = '--stream'
        item.desc = 'turn on stream mode'
        item.default = false
        item.value = true
      end

      define_option(:request_task_worker) do |item|
        item.long = '--request-task-worker=N'
        item.desc = 'set request number of task workers'
        item.default = 1
        item.value = proc {|n| n.to_i}
      end

      define_option(:params) do |item|
        item.long = '--params="{Var:1,...}"'
        item.desc = "set user parameters"
        item.default = Lang::ParameterSetSequence.new
        item.action = proc do |cmd, option, str|
          begin
            option[:params] = option[:params].merge(Util.parse_param_set(str))
          rescue Parslet::ParseFailed => e
            raise OptionError.new("invalid parameters \"%s\" in %s" % [str, cmd.command_name])
          end
        end
      end

      define_option(:stand_alone) do |item|
        item.long = '--stand-alone'
        item.desc = 'turn on stand alone mode'
        item.default = false
        item.action = proc do |_, option|
          option[:stand_alone] = true
          option[:without_tuple_space_provider] = true
        end
      end

      define_option(:dry_run) do |item|
        item.long = '--dry-run'
        item.desc = 'turn on dry run mode'
        item.default = false
        item.value = true
      end

      option_item(:features).default = Global.features + "& ^Interactive"

      define_option(:relay) do |item|
        item.long = '--relay=URI'
        item.desc = 'turn on relay mode and set relay address'
        item.default = nil
        item.value = proc {|uri| uri}
      end

      define_option(:rehearse) do |item|
        item.long = '--rehearse [SCENARIO]'
        item.desc = 'rehearse the scenario'
        item.value = proc {|scenario_name| scenario_name || :anything}
      end

      define_option(:timeout) do |item|
        item.long = '--timeout SEC'
        item.desc = 'timeout processing after SEC'
        item.value = proc {|sec| sec.to_i}
      end

      validate_option do |option|
        unless option[:task_worker] > 0 or
            (not(option[:stand_alone]) and option[:task_worker] == 0)
          raise OptionError.new("option error: invalid resource size '%s'" % option[:task_worker])
        end

        if option[:stream] and option[:input_location].nil?
          raise OptionError.new("option error: no input URI on stream mode")
        end
      end

      #
      # instance methods
      #

      attr_reader :task_worker
      attr_reader :tuple_space # client's tuple space

      #
      # command lifecycle: setup phase
      #

      # setup_phase :timeout => 20 # because of setup for dropbox...
      setup :parent_process_connection, :module => CommonCommandAction
      setup :variable
      setup :ftp_server
      setup :tuple_space
      setup :output_location
      setup :lang_environment
      setup :package

      def setup_variable
        @spawner_threads = ThreadGroup.new
      end

      # Setup FTP server with the URI.
      def setup_ftp_server
        if uri = option[:myftp]
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

      def setup_output_location
        # setup location
        case option[:output_location]
        when Location::LocalLocation
          option[:output_location] = Location[option[:output_location].path.expand_path]
          option[:output_location].path.mkpath
        when Location::DropboxLocation
          Location::DropboxLocation.setup_for_cui_client(tuple_space_server)
        end

        # mkdir
        if not(option[:output_location].exist?)
          option[:output_location].mkdir
        end

        # set base location into tuple space
        @tuple_space.set_base_location(option[:output_location])
      end

      def setup_tuple_space
        # run tuple space server
        @tuple_space = TupleSpace::TupleSpaceServer.new(task_worker_resource: option[:request_task_worker])
        set_tuple_space(@tuple_space)
        Global.front.set_tuple_space(@tuple_space)

        # write tuples
        write(TupleSpace::ProcessInfoTuple.new('standalone', 'Standalone'))
        write(TupleSpace::DryRunTuple.new(option[:dry_run]))
      end

      def setup_lang_environment
        @env = Lang::Environment.new
      end

      # Read a PIONE package. This setups package sharing and secnario handling also.
      def setup_package
        # package is not found
        if @argv.first.nil?
          abort("There are no PIONE documents or packages.")
        end

        # read package
        @package_handler = Package::PackageReader.read(Location[@argv.first])
        @env = @package_handler.eval(@env)

        # upload the package
        @package_handler.upload(option[:output_location] + "package")

        # check rehearse scenario
        if option[:rehearse] and not(@package_handler.info.scenarios.empty?)
          if @scenario_handler = @package_handler.find_scenario(option[:rehearse])
            option[:input_location] = @scenario_handler.input
          else
            abort "the scenario not found: %s" % option[:rehearse]
          end
        end
      rescue Package::InvalidPackage => e
        abort("Package error: " + e.message)
      rescue Lang::ParserError => e
        abort("Pione syntax error: " + e.message)
      rescue Lang::LangError => e
        abort("Pione language error: %s(%s)" % [e.message, e.class.name])
      end

      # Connect relay server.
      def start_relay_connection
        Global.relay_tuple_space_server = @tuple_space
        @relay_ref = DRbObject.new_with_uri(option[:relay])
        @relay_ref.__connect
        if Global.show_communication
          puts "you connected the relay: %s" % option[:relay]
        end
        # watchdog for the relay server
        Thread.start do
          Global.relay_receiver.thread.join
          abort("relay server disconnected: %s" % @relay_ref.__drburi)
        end
      rescue DRb::DRbConnError => e
        puts "You couldn't connect the relay server: %s" % @relay_ref.__drburi
        puts "%s: %s" % [e.class, e.message]
        caller.each {|line| puts "    %s" % line}
        abort
      rescue Relay::RelaySocket::AuthError
        abort("You failed authentication to connect the relay server: %s" % @relay_ref.__drburi)
      end

      #
      # command lifecycle: execution phase
      #

      execute :job_terminator
      execute :messenger
      execute :logger
      execute :input_generator
      execute :tuple_space_provider
      execute :task_worker
      execute :job_manager
      execute :check_rehearsal_result

      def execute_job_terminator
        @job_terminator = Agent::JobTerminator.start(@tuple_space) do |status|
          if status.error?
            abort("pione-client catched the error: %s" % status.message)
          else
            terminate
          end
        end
      end

      # Start a messenger agent.
      def execute_messenger
        # select receiver
        if option[:parent_front] and option[:parent_front][:message_log_receiver]
          # delegate parent's receiver
          receiver = option[:parent_front][:message_log_receiver]
        else
          # CUI receiver
          receiver = Log::CUIMessageLogReceiver.new
        end

        @messenger = Agent::Messenger.new(@tuple_space, receiver).start
      end

      # Start a logger agent.
      def execute_logger
        @logger = Agent::Logger.start(@tuple_space, option[:output_location])
      end

      # Start an input generator agent.
      def execute_input_generator
        @input_generator =
          Agent::InputGenerator.start(@tuple_space, :dir, option[:input_location], option[:stream])
      end

      # Spawn a tuple space provider.
      def execute_tuple_space_provider
        unless option[:without_tuple_space_provider]
          thread = Thread.new do
            begin
              spawner = Command::PioneTupleSpaceProvider.spawn
              spawner.when_terminated do
                unless termination?
                  abort("%s is terminated because child tuple space provider is maybe dead." % command_name)
                end
              end
              @tuple_space_provider = spawner.child_front
            rescue SpawnError => e
              if termination?
                Log::Debug.system(e.message)
              else
                abort(e.message)
              end
            end
          end
          @spawner_threads.add(thread)
        end
      end

      # Start task workers. Task worker agents are in the process if the client
      # is stand-alone mode, otherwise they are in new processes.
      def execute_task_worker
        @task_workers = [] # this is available in stand alone mode
        option[:task_worker].times do
          # we don't wait workers start up because of performance
          thread = Thread.new do
            if option[:stand_alone]
              @task_workers << Agent::TaskWorker.start(@tuple_space, Global.expressional_features, @env)
            else
              begin
                Command::PioneTaskWorker.spawn(Global.features, @tuple_space.uuid)
              rescue SpawnError => e
                if termination?
                  Log::Debug.system(e.message)
                else
                  abort(e.message)
                end
              end
            end
          end
          @spawner_threads.add(thread)
        end
      end

      # Start a job manager agent.
      def execute_job_manager
        param_set = Lang::ParameterSet.new

        # use paramerter set on command option
        if option[:params] and not(option[:params].pieces.empty?)
          param_set = option[:params].pieces.first
        end

        # use parameter set on scenario
        if not(@scenario_handler.nil?) and @scenario_handler.info.textual_param_sets
          param_set = Util.parse_param_set(@scenario_handler.info.textual_param_sets).pieces.first
        end

        # start
        @job_manager =
          Agent::JobManager.start(@tuple_space, @env, @package_handler, param_set, option[:stream])
        Timeout::timeout(option[:timeout]) do
          @job_manager.wait_until_terminated(nil)
        end
      rescue Agent::JobError => e
        abort(e.message)
      rescue Timeout::Error => e
        abort("Job timed out after %s sec." % option[:timeout])
      end

      # Check rehearsal result.
      def execute_check_rehearsal_result
        return unless option[:rehearse] and not(@package_handler.info.scenarios.empty?)
        return unless scenario = @package_handler.find_scenario(option[:rehearse])

        errors = scenario.validate(option[:output_location])
        if errors.empty?
          Log::SystemLog.info "Rehearsal Result: Succeeded"
        else
          puts "Rehearsal Result: Failed"
          errors.each {|error| puts "- %s" % error.to_s}
          Global.exit_status = false
        end
      end

      #
      # command lifecycle: termination phase
      #

      termination_phase :timeout => 10
      # kill task worker bootstrap threads before terminate child processes
      terminate :process_job => :spawner_thread
      terminate :child_process, :module => CommonCommandAction
      terminate :process_job => :job_manager
      terminate :process_job => :job_terminator
      terminate :process_job => :task_worker
      terminate :process_job => :input_generator
      terminate :process_job => :logger
      terminate :process_job => :messenger
      terminate :process_job => :tuple_space

      # Terminate spawner threads. This is needed for the case that requested
      # job reaches end before task worker processes finish to be spawned.
      def terminate_spawner_thread
        @spawner_threads.list.each {|thread| thread.kill}
      end

      # Terminate job manager agent. Be careful that main thread of
      # `pione-client` command waits to stop the job manager's chain thread, so
      # pione-client has cannot terminate until the agent has terminated. we
      # need to terminate it after job manager terminated.
      def terminate_job_manager
        if @job_manager and not(@job_manager.terminated?)
          @job_manager.terminate
        end
      end

      # Terminate job terminator agent.
      def terminate_job_terminator
        if @job_terminator and not(@job_terminator.terminated?)
          @job_terminator.terminate
        end
      end

      # Terminate task worker agents.
      def terminate_task_worker
        if option[:stand_alone] and @task_workers
          @task_workers.each {|task_worker| task_worker.terminate}
        end
      end

      # Terminate input generator agent.
      def terminate_input_generator
        if @input_generator and not(@input_generator.terminated?)
          @input_generator.terminate
        end
      end

      # Terminate logger agent.
      def terminate_logger
        if @logger and not(@logger.terminated?)
          @logger.terminate
        end
      end

      # Terminate messenger agent.
      def terminate_messenger
        if @messenger and not(@messenger.terminated?)
          @messenger.terminate
        end
      end

      # Terminate tuple space agent.
      def terminate_tuple_space
        if @tuple_space
          @tuple_space.terminate
        end
      end
    end
  end
end
