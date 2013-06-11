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
        use :debug
        use :color
        use :show_communication
        use :my_ip_address
        use :presence_notification_address
        use :show_presence_notifier
        use :task_worker
        use :features

        define(:input_location) do |item|
          item.short = '-i LOCATION'
          item.long = '--input=LOCATION'
          item.desc = 'set input directory'
          item.value = proc do |uri|
            begin
              Location[uri]
            rescue ArgumentError
              abort("ERROR: bad location '%s'" % uri)
            end
          end
        end

        define(:output_location) do |item|
          item.short = '-o LOCATION'
          item.long = '--output=LOCATION'
          item.desc = 'set output directory'
          item.default = Location["local:./output/"]
          item.action = proc do |option, uri|
            begin
              option[:output_location] = Location[uri]
              if URI.parse(uri).scheme == "myftp"
                option[:myftp] = URI.parse(uri).normalize
              end
            rescue ArgumentError
              abort("ERROR: bad location '%s'" % uri)
            end
          end
        end

        define(:stream) do |item|
          item.long = '--stream'
          item.desc = 'turn on stream mode'
          item.default = false
          item.value = true
        end

        define(:request_task_worker) do |item|
          item.long = '--request-task-worker=N'
          item.desc = 'set request number of task workers'
          item.default = 1
          item.value = proc {|n| n.to_i}
        end

        define(:params) do |item|
          item.long = '--params="{Var:1,...}"'
          item.desc = "set user parameters"
          item.default = Model::Parameters.empty
          item.action = proc do |option, str|
            begin
              params = DocumentTransformer.new.apply(
                DocumentParser.new.parameters.parse(str)
              )
              option[:params].merge!(params)
            rescue Parslet::ParseFailed => e
              $stderr.puts "invalid parameters: " + str
              Util::ErrorReport.print(e)
              abort
            end
          end
        end

        define(:stand_alone) do |item|
          item.long = '--stand-alone'
          item.desc = 'turn on stand alone mode'
          item.default = false
          item.action = proc do |option|
            option[:stand_alone] = true
            option[:without_tuple_space_provider] = true
          end
        end

        define(:dry_run) do |item|
          item.long = '--dry-run'
          item.desc = 'turn on dry run mode'
          item.default = false
          item.value = true
        end

        item(:features).default = "^Interactive"

        define(:relay) do |item|
          item.long = '--relay=URI'
          item.desc = 'turn on relay mode and set relay address'
          item.default = nil
          item.value = proc {|uri| uri}
        end

        define(:list_params) do |item|
          item.long = '--list-params'
          item.desc = 'show user parameter list in the document'
          item.value = true
        end

        define(:rehearse) do |item|
          item.long = '--rehearse[=SCENARIO]'
          item.desc = 'rehearse the scenario'
          item.value = proc {|scenario_name| scenario_name || :anything}
        end

        define(:without_tuple_space_provider) do |item|
          item.long = '--without-tuple-space-provider'
          item.desc = 'process without tuple space provider'
          item.value = true
        end

        validate do |option|
          unless option[:task_worker] > 0 or
              (not(option[:stand_alone]) and option[:task_worker] == 0)
            abort("option error: invalid resource size '%s'" % option[:task_worker])
          end

          if option[:stream] and option[:input_location].nil?
            abort("option error: no input URI on stream mode")
          end
        end
      end

      attr_reader :task_worker
      attr_reader :features
      attr_reader :tuple_space_server

      def initialize(*options)
        super(*options)
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
          exit
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
        # package is not found
        if @argv.first.nil?
          abort("There are no PIONE documents or packages.")
        end

        # read package
        @package = Component::PackageReader.read(Location[@argv.first])
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
        features = DocumentTransformer.new.apply(
          DocumentParser.new.feature_expr.parse(option[:features])
        )
        option[:task_worker].times do
          if option[:stand_alone]
            Thread.new do
              Agent[:task_worker].start(@tuple_space_server, features)
            end
          else
            Thread.new do
              @child_process_infos << Agent[:task_worker].spawn(Global.front, Util::UUID.generate, option[:features])
            end
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
