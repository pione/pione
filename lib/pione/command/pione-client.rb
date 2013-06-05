module Pione
  module Command
    # PioneClient is a command to request processing.
    class PioneClient < FrontOwnerCommand
      include TupleSpaceServerInterface

      define_info do
        set_name "pione-client"
        set_tail {|cmd| Global.front.uri}
        set_banner "Requests to process PIONE document."
      end

      define_option do
        use Option::TaskWorkerOwnerOption
        use Option::TupleSpaceProviderOwnerOption

        default :output_location, Location["local:./output/"]
        default :stream, false
        default :params, Model::Parameters.empty
        default :dry_run, false
        default :task_worker, Agent::TaskWorker.default_number
        default :request_task_worker, 1
        default :stand_alone, false
        default :relay, nil
        default :filename, "-"
        default :without_tuple_space_provider, false
        default :features, "^Interactive"
        default :list_params, false

        # --input
        option('-i LOCATION', '--input=LOCATION', 'set input directory') do |data, uri|
          begin
            data[:input_location] = Location[uri]
          rescue ArgumentError
            abort("opiton error: bad location '%s'" % uri)
          end
        end

        # --output
        option('-o LOCATION', '--output=LOCATION', 'set output directory') do |data, uri|
          begin
            data[:output_location] = Location[uri]
            if URI.parse(uri).scheme == "myftp"
              data[:myftp] = URI.parse(uri).normalize
            end
          rescue ArgumentError
            abort("opiton error: bad location '%s'" % uri)
          end
        end

        # --stream
        option('--stream', 'turn on stream mode') do |data|
          data[:stream] = true
        end

        # --request-task-worker
        option('--request-task-worker=N', 'set request number of task workers') do |data, n|
          data[:request_task_worker] = n.to_i
        end

        # --params
        option('--params="{Var:1,...}"', "set user parameters") do |data, str|
          begin
            params = DocumentTransformer.new.apply(
              DocumentParser.new.parameters.parse(str)
            )
            data[:params].merge!(params)
          rescue Parslet::ParseFailed => e
            puts "invalid parameters: " + str
            Util::ErrorReport.print(e)
            abort
          end
        end

        # --stand-alone
        option('--stand-alone', 'turn on stand alone mode') do |data|
          data[:stand_alone] = true
          data[:without_tuple_space_provider] = true
        end

        # --dry-run
        option('--dry-run', 'turn on dry run mode') do |data, b|
          data[:dry_run] = true
        end

        # --relay
        option('--relay=URI', 'turn on relay mode and set relay address') do |data, uri|
          data[:relay] = uri
        end

        # --name
        option('--name=NAME') do |data, name|
          data[:name] = name
        end

        # --list-parameters
        option('--list-params', 'show user parameter list in the document') do |data|
          data[:list_params] = true
        end

        option('--rehearse[=SCENARIO]', 'rehearse the scenario') do |data, scenario_name|
          data[:rehearse] = scenario_name || :anything
        end

        validate do |data|
          unless data[:task_worker] > 0 or
              (not(data[:stand_alone]) and data[:task_worker] == 0)
            abort("option error: invalid resource size '%s'" % data[:task_worker])
          end

          if data[:stream] and data[:input_location].nil?
            abort("option error: no input URI on stream mode")
          end
        end
      end

      attr_reader :task_worker
      attr_reader :features
      attr_reader :tuple_space_server

      def initialize
        super()
        @worker_threads = []
        @tuple_space_server = nil
        @child_process_infos = []
      end

      private

      def create_front
        Front::ClientFront.new(self)
      end

      prepare do
        # FTP server
        setup_ftp_server(myftp) if myftp = option[:myftp]

        # run tuple space server
        @tuple_space_server = TupleSpaceServer.new(task_worker_resource: option[:request_task_worker])
        set_tuple_space_server(@tuple_space_server)

        # setup output location
        case option[:output_location]
        when Location::LocalLocation
          option[:output_location] = Location[option[:output_location].path.expand_path]
          option[:output_location].path.mkpath
        when Location::DropboxLocation
          setup_dropbox
        end

        @tuple_space_server.set_base_location(option[:output_location])
      end

      start(:pre) {read_package}

      # Print list of user parameters.
      start do
        if option[:list_params]
          puts "Parameters:"
          unless @package.params.empty?
            @package.params.data.select{|var, val| var.user_param}.each do |var, val|
              puts "  %s := %s" % [var.name, val.textize]
            end
          else
            puts "  there are no user parameters in %s" % ARGF.path
          end
          exit!
        end
      end

      # Run processing.
      start do
        # write tuples
        write(Tuple[:process_info].new('standalone', 'Standalone'))
        write(Tuple[:dry_run].new(option[:dry_run]))

        # start
        start_relay_connection if option[:relay]
        start_precedent_agents
        start_task_workers
        start_process_manager

        # check result
        check_rehearsal_result if option[:rehearse]

        @child_process_infos.each {|info| info.kill}
        @child_process_infos.each {|info| info.wait}
      end

      terminate do
        if @terminated
          @terminated = true
          Global.monitor.synchronize do
            # kill the thread for starting tuple space provider
            if @start_tuple_space_provider_thread
              if @start_tuple_space_provider_thread.alive?
                @start_tuple_space_provider_thread.kill
              end
            end

            @logger.terminate

            # terminate tuple space provider
            if @tuple_space_provider
              @tuple_space_provider.terminate
            end
          end
        end
      end

      private

      # Setup FTP server with the URI.
      def setup_ftp_server(uri)
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

      # Read a package.
      #
      # @return [void]
      def read_package
        # package is not found.
        if ARGF.filename == "-"
          abort("There are no process definition documents.")
        end

        # read package
        @package = Component::PackageReader.read(Location[ARGF.path])
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
      rescue Pione::Model::PioneModelTypeError, Pione::Model::VariableBindingError => e
        abort("Pione model error: " + e.message)
      end

      # Start agent activities.
      #
      # @return [void]
      def start_precedent_agents
        # messenger
        @messenger = Agent[:messenger].start(@tuple_space_server)

        # logger
        @logger = Agent[:logger].start(@tuple_space_server, option[:output_location])

        # rule provider
        @rule_loader = Agent[:rule_provider].start(@tuple_space_server)
        @rule_loader.read_rules(@package)
        @rule_loader.wait_till(:request_waiting)

        # input generators
        generator_method = option[:stream] ? :start_by_stream : :start_by_dir
        gen = Agent[:input_generator].send(
          generator_method, @tuple_space_server, option[:input_location]
        )

        # command listener
        @command_listener = Agent[:command_listener].start(@tuple_space_server, self)

        # start tuple space provider and connect tuple space server
        unless option[:without_tuple_space_provider]
          @start_tuple_space_provider_thread = Thread.new do
            @tuple_space_provider = Pione::TupleSpaceProvider.instance(@child_process_infos)
            @tuple_space_provider.add_tuple_space_server(@tuple_space_server)
          end
        end
      end

      # Start task workers.
      def start_task_workers
        option[:task_worker].times do
          Thread.new do
            @child_process_infos << Agent[:task_worker].spawn(Global.front, Util::UUID.generate, option[:features])
          end
        end
      end

      # Start process manager agent.
      def start_process_manager
        @agent = Agent[:process_manager].start(@tuple_space_server, @package, option[:params], option[:stream])
        @agent.running_thread.join
      end

      # Connect relay server.
      def start_relay_connection
        Global.relay_tuple_space_server = @tuple_space_server
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

      # Check rehearsal result.
      def check_rehearsal_result
        return unless option[:rehearse] and not(@package.scenarios.empty?)
        return unless scenario = @package.find_scenario(option[:rehearse])

        errors = scenario.validate(option[:output_location])
        if errors.empty?
          puts "Rehearsal Result: Succeeded"
        else
          puts "Rehearsal Result: Failed"
          errors.each {|error| puts "- %s" % error.to_s}
          Global.exit_status = false
        end
      end
    end
  end
end
