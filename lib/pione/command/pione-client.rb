module Pione
  module Command
    # PioneClient is a command to request processing.
    class PioneClient < FrontOwnerCommand
      define_info do
        set_name "pione-client"
        set_tail {|cmd|
          args = [cmd.option[:filename], cmd.option[:output_uri], cmd.option[:stream]]
          "{Document: %s, OutputURI: %s, Stream: %s}" % args
        }
        set_banner "Requests to process PIONE document."
      end

      define_option do
        use Option::TaskWorkerOwnerOption
        use Option::TupleSpaceProviderOwnerOption

        default :output_location, Location["local:./output/"]
        default :stream, false
        default :params, Model::Parameters.empty
        default :dry_run, false
        default :task_worker, [Util.core_number - 1, 1].max
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
        option('--params="{Var:1,...}"', "set &main:Main rule's parameters") do |data, str|
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
      attr_reader :name

      def initialize
        super()
        @worker_threads = []
        @tuple_space_server = nil
      end

      private

      def create_front
        Front::ClientFront.new(self)
      end

      prepare do
        @filename = ARGF.filename

        # ftp server
        if myftp = option[:myftp]
          location = Location[myftp.path]
          location.path.mkdir unless location.exist?
          if myftp.userinfo
            Util::FTPServer.auth_info = Util::FTPAuthInfo.new(myftp.user, myftp.password)
          end
          if myftp.port
            Util::FTPServer.port = myftp.port
          end
          Util::FTPServer.start(Util::FTPLocalFS.new(location))
        end

        # setup log location
        @log_location = option[:output_location] + Time.now.strftime("pione_%Y%m%d%H%M%S.log")

        @tuple_space_server = TupleSpaceServer.new(
          task_worker_resource: option[:request_task_worker]
        )

        # setup base uri
        case option[:output_location]
        when Location::LocalLocation
          option[:output_location] = Location[option[:output_location].path.expand_path]
          option[:output_location].path.mkpath
        when Location::DropboxLocation
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

        @tuple_space_server.set_base_location(option[:output_location])
      end

      start do
        read_process_document

        if option[:list_params]
          print_parameter_list
          exit!
        end

        write_tuples
        connect_relay if option[:relay]
        start_agents

        # start tuple space provider with thread
        # the thread is terminated when the client terminated
        unless option[:without_tuple_space_provider]
          @start_tuple_space_provider_thread = Thread.new do
            start_tuple_space_provider
          end
        end

        start_workers
        @agent = Agent[:process_manager].start(@tuple_space_server, @document, option[:params], option[:stream])
        @agent.running_thread.join
      end

      terminate do
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

      private

      # Read PIONE process document.
      #
      # @return [void]
      def read_process_document
        # process definition document is not found.
        if ARGF.filename == "-"
          abort("There are no process definition documents.")
        end

        # get script dirname
        @dir = File.dirname(File.expand_path(__FILE__))

        location = Location[ARGF.path]

        # read process document
        begin
          if location.directory?
            # package
            @document = Component::PackageReader.new(location).read
            @document.upload(option[:output_location] + "package")
          else
            @document = Component::Document.parse(location.read)
          end
        rescue Pione::Parser::ParserError => e
          abort("Pione syntax error: " + e.message)
        rescue Pione::Model::PioneModelTypeError, Pione::Model::VariableBindingError => e
          abort("Pione model error: " + e.message)
        end
      end

      # Write initial tuples.
      #
      # @return [void]
      def write_tuples
        [ Tuple[:process_info].new('standalone', 'Standalone'),
          Tuple[:dry_run].new(option[:dry_run])
        ].each {|tuple| @tuple_space_server.write(tuple) }
      end

      # Start agent activities.
      #
      # @return [void]
      def start_agents
        # messenger
        @messenger = Agent[:messenger].start(@tuple_space_server)

        # logger
        @logger = Agent[:logger].start(@tuple_space_server, @log_location)

        # rule provider
        @rule_loader = Agent[:rule_provider].start(@tuple_space_server)
        @rule_loader.read_document(@document)
        @rule_loader.wait_till(:request_waiting)

        # input generators
        generator_method = option[:stream] ? :start_by_stream : :start_by_dir
        gen = Agent[:input_generator].send(
          generator_method, @tuple_space_server, option[:input_location]
        )

        # command listener
        @command_listener = Agent[:command_listener].start(@tuple_space_server, self)
      end

      # Wake up tuple space provider process and connect my tuple space server
      # to it.
      def start_tuple_space_provider
        @tuple_space_provider = Pione::TupleSpaceProvider.instance
        @tuple_space_provider.add_tuple_space_server(@tuple_space_server)
      end

      # Start task workers.
      #
      # @return [void]
      def start_workers
        option[:task_worker].times do
          Thread.new {
            Agent[:task_worker].spawn(Global.front, Util.generate_uuid, option[:features])
          }
        end
      end

      # Connect relay server.
      #
      # @return [void]
      def connect_relay
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

      # Print parameter list of the document.
      #
      # @return [void]
      def print_parameter_list
        puts "Parameters:"
        @document.params.data.select{|var, val| var.user_param}.each do |var, val|
          puts "  %s := %s" % [var.name, val.textize]
        end
      end
    end
  end
end
