module Pione
  module Command
    # PioneClient is a command to request processing.
    class PioneClient < BasicCommand
      include TupleSpace::TupleSpaceInterface

      #
      # basic informations
      #

      command_name("pione-client") {|cmd| "front: %s" % Global.front.uri}
      command_banner "Process PIONE document."
      command_front Front::ClientFront

      #
      # options
      #

      use_option :debug
      use_option :color
      use_option :my_ip_address
      use_option :presence_notification_address
      use_option :task_worker
      use_option :features

      option_default(:action_mode, :process_job)

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
        item.action = proc do |command_name, option, uri|
          begin
            option[:output_location] = Location[uri]
            if URI.parse(uri).scheme == "myftp"
              option[:myftp] = URI.parse(uri).normalize
            end
          rescue ArgumentError
            raise OptionError.new("output location '%s' is bad in %s" % [uri, command_name])
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
        item.action = proc do |command_name, option, str|
          begin
            stree = DocumentParser.new.parameter_set.parse(str)
            opt = {package_name: "-", filename: "-"}
            params = DocumentTransformer.new.apply(stree, opt)
            option[:params].merge!(params)
          rescue Parslet::ParseFailed => e
            raise OptionError.new("invalid parameters \"%s\" in %s" % [str, command_name])
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

      define_option(:list_params) do |item|
        item.long = '--list-params'
        item.desc = 'show user parameter list in the document'
        item.action = proc {|_, option| option[:action_mode] = :list_params}
      end

      define_option(:rehearse) do |item|
        item.long = '--rehearse[=SCENARIO]'
        item.desc = 'rehearse the scenario'
        item.value = proc {|scenario_name| scenario_name || :anything}
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

      setup_phase :timeout => 20
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

      # Setup dropbox.
      def setup_dropbox
        # start session
        session = nil
        consumer_key = nil
        consumer_secret = nil

        cache = Pathname.new("~/.pione/dropbox_api.cache").expand_path
        if cache.exist?
          session = DropboxSession.deserialize(cache.read)
          Location::Dropbox.set_session(session)
          consumer_key = session.instance_variable_get(:@consumer_key)
          consumer_secret = session.instance_variable_get(:@consumer_secret)
        else
          api = YAML.load(Pathname.new("~/.pione/dropbox_api.yml").expand_path.read)
          consumer_key = api["key"]
          consumer_secret = api["secret"]
          session = DropboxSession.new(consumer_key, consumer_secret)
          Location::Dropbox.set_session(session)
          authorize_url = session.get_authorize_url
          puts "AUTHORIZING", authorize_url
          puts "Please visit that web page and hit 'Allow', then hit Enter here."
          STDIN.gets
          session.get_access_token

          # cache session
          cache.open("w+") {|c| c.write session.serialize}
        end

        # check session state
        unless session.authorized?
          abort("We cannot authorize dropbox access to PIONE.")
        end

        # share access token in tuple space
        Location::Dropbox.share_access_token(tuple_space_server, consumer_key, consumer_secret)
      end

      def setup_output_location
        case option[:output_location]
        when Location::LocalLocation
          option[:output_location] = Location[option[:output_location].path.expand_path]
          option[:output_location].path.mkpath
        when Location::DropboxLocation
          setup_dropbox
        end
        @tuple_space.set_base_location(option[:output_location])
      end

      def setup_tuple_space
        # run tuple space server
        @tuple_space = TupleSpace::TupleSpaceServer.new(task_worker_resource: option[:request_task_worker])
        set_tuple_space(@tuple_space)
        Global.front.set_tuple_space(@tuple_space)

        # write tuples
        write(Tuple[:process_info].new('standalone', 'Standalone'))
        write(Tuple[:dry_run].new(option[:dry_run]))
      end

      def setup_lang_environment
        @env = Lang::Environment.new
      end

      # Read a package.
      def setup_package
        # package is not found
        if @argv.first.nil?
          abort("There are no PIONE documents or packages.")
        end

        # read package
        @package = Component::PackageReader.read(Location[@argv.first])
        @package_id = @package.eval(@env)
        @env = @env.set(current_package_id: @package_id)
        @package.upload(option[:output_location] + "package")

        # check rehearse scenario
        if option[:rehearse] and not(@package.scenarios.empty?)
          if scenario = @package.find_scenario(option[:rehearse])
            option[:input_location] = scenario.input
          else
            abort "the scenario not found: %s" % option[:rehearse]
          end
        end
      rescue Pione::Parser::ParserError => e
        abort("Pione syntax error: " + e.message)
      rescue Pione::Lang::LangError => e
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

      # mode "list params"
      execute :list_params => :list_params

      # mode "process_job"
      execute :process_job => :job_terminator
      execute :process_job => :messenger
      execute :process_job => :logger
      execute :process_job => :input_generator
      execute :process_job => :tuple_space_provider
      execute :process_job => :task_worker
      execute :process_job => :process_manager
      execute :process_job => :check_rehearsal_result

      # Print list of user parameters.
      def execute_list_params
        Util::PackageParametersList.print(@env, @package_id)
      end

      def execute_job_terminator
        @job_terminator = Agent::JobTerminator.start(@tuple_space) do
          terminate
        end
      end

      # Start a messenger agent.
      def execute_messenger
        @messenger = Agent::Messenger.start(@tuple_space)
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
              abort(e.message)
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
                abort(e.message)
              end
            end
          end
          @spawner_threads.add(thread)
        end
      end

      # Start process manager agent.
      def execute_process_manager
        @process_manager =
          Agent::ProcessManager.start(@tuple_space, @env, @package, option[:params], option[:stream])
        @process_manager.wait_until_terminated(nil)
      end

      # Check rehearsal result.
      def execute_check_rehearsal_result
        return unless option[:rehearse] and not(@package.scenarios.empty?)
        return unless scenario = @package.find_scenario(option[:rehearse])

        errors = scenario.validate(option[:output_location])
        if errors.empty?
          System.show "Rehearsal Result: Succeeded"
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
      terminate :process_job => :process_manager
      terminate :process_job => :task_worker
      terminate :process_job => :input_generator
      terminate :process_job => :logger
      terminate :process_job => :messenger
      terminate :process_job => :tuple_space

      # Terminate spawner threads. This is needed for like the situation that
      # requested job reaches end before task worker processes finished to be
      # spawned.
      def terminate_spawner_thread
        @spawner_threads.list.each {|thread| thread.kill}
      end

      # Terminate process manager
      def terminate_process_manager
        @process_manager.terminate if @process_manager
      end

      # Terminate task worker agents.
      def terminate_task_worker
        if option[:stand_alone] and @task_workers
          @task_workers.each {|task_worker| task_worker.terminate}
        end
      end

      # Terminate input generator agent.
      def terminate_input_generator
        @input_generator.terminate if @input_generator
      end

      # Terminate logger agent.
      def terminate_logger
        @logger.terminate if @logger
      end

      # Terminate messenger agent.
      def terminate_messenger
        @messenger.terminate if @messenger
      end

      # Terminate tuple space.
      def terminate_tuple_space
        @tuple_space.terminate if @tuple_space
      end
    end
  end
end
