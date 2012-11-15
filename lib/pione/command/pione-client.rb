module Pione
  module Command
    class PioneClient < FrontOwnerCommand
      use_option_module CommandOption::TupleSpaceProviderOwnerOption

      set_program_name("pione-client") do
        [@filename, "-b %s" % @base_uri, @stream ? "--stream" : ""].join(" ")
      end

      set_program_message <<TXT
Requests to process PIONE document.
TXT

      define_option('-i DIR', '--input-dir=DIR', 'set input data directory') do |dir|
        @input_dir = dir
      end

      define_option('-b URI', '--base-uri=URI', 'set base URI') do |uri|
        @base_uri = ::URI.parse(uri)
      end

      define_option('--log=PATH', 'set log path') do |path|
        @log_path = path
      end

      define_option('--stream', 'turn on stream mode') do
        @stream = true
      end

      define_option('-r N', '--resource=N', 'set resource number') do |n|
        @resource = n.to_i
      end

      define_option('--params="{Var:1,...}"', "set &main:Main rule's parameters") do |str|
        begin
          @params = DocumentTransformer.new.apply(
            DocumentParser.new.parameters.parse(str)
          )
        rescue Parslet::ParseFailed => e
          puts "invalid parameters: " + str
          Util::ErrorReport.print(e)
          abort
        end
      end

      define_option('--stand-alone', 'turn on stand alone mode') do
        @stand_alone = true
        @without_tuple_space_provider = true
      end

      define_option('--dry-run', 'turn on dry run mode') do |b|
        @dry_run = true
      end

      define_option('--relay URI', 'turn on relay mode and set relay address') do |uri|
        @relay = uri
      end

      attr_reader :tuple_space_server

      def initialize
        super()
        @input_dir = nil
        @base_uri = URI.parse("local:./output/")
        @log_path = "log.txt"
        @stream = false
        @params = Parameters.empty
        @dry_run = false
        @resource = [Util.core_number - 1, 1].max
        @worker_threads = []
        @stand_alone = false
        @relay = nil
        @filename = "-"
        @without_tuple_space_provider = false
      end

      private

      def validate_options
        unless @resource > 0 or (not(@stand_alone) and @resource == 0)
          abort("error: invalid resource size: %s" % @resource)
        end

        if @stream and @input_dir.nil?
          abort("error: no input dir on stream mode")
        end
      end

      def create_front
        Front::ClientFront.new(self)
      end

      def prepare
        super

        @filename = ARGF.filename

        @tuple_space_server = TupleSpaceServer.new(
          task_worker_resource: @resource
        )

        # setup base uri
        case @base_uri.scheme
        when "local"
          FileUtils.makedirs(@base_uri.path)
          @base_uri = @base_uri.absolute
        when "dropbox"
          # start session
          session = nil
          consumer_key = nil
          consumer_secret = nil

          cache = Pathname.new("~/.pione/dropbox_api.cache").expand_path
          if cache.exist?
            session = DropboxSession.deserialize(cache.read)
            Resource::Dropbox.set_session(session)
            consumer_key = session.instance_variable_get(:@consumer_key)
            consumer_secret = session.instance_variable_get(:@consumer_secret)
          else
            api = YAML.load(Pathname.new("~/.pione/dropbox_api.yml").expand_path.read)
            consumer_key = api["key"]
            consumer_secret = api["secret"]
            session = DropboxSession.new(consumer_key, consumer_secret)
            Resource::Dropbox.set_session(session)
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
          Resource::Dropbox.share_access_token(tuple_space_server, consumer_key, consumer_secret)
        end

        @base_uri = @base_uri.as_directory.to_s
        @tuple_space_server.set_base_uri(@base_uri)
      end

      def start
        read_process_document
        write_tuples
        connect_relay if @relay
        start_agents
        start_tuple_space_provider unless @without_tuple_space_provider
        start_workers
        @agent = Agent[:process_manager].start(@tuple_space_server, @document, @params)
        @agent.running_thread.join
        terminate
      end

      def terminate
        if @tuple_space_provider
          @tuple_space_provider.terminate
        end
        super
      end

      private

      def read_process_document
        # process definition document is not found.
        if ARGF.filename == "-"
          abort("There are no process definition documents.")
        end

        # get script dirname
        @dir = File.dirname(File.expand_path(__FILE__))

        # read process document
        begin
          @document = Document.parse(ARGF.read)
        rescue Pione::Parser::ParserError => e
          abort("Pione syntax error: " + e.message)
        rescue Pione::Model::PioneModelTypeError, Pione::Model::VariableBindingError => e
          abort("Pione model error: " + e.message)
        end
      end

      def write_tuples
        [ Tuple[:process_info].new('standalone', 'Standalone'),
          Tuple[:dry_run].new(@dry_run)
        ].each {|tuple| @tuple_space_server.write(tuple) }
      end

      def start_agents
        # logger
        Agent[:logger].start(@tuple_space_server, File.open(@log_path, "w+"))

        # rule provider
        @rule_loader = Agent[:rule_provider].start(@tuple_space_server)
        @rule_loader.read_document(@document)
        @rule_loader.wait_till(:request_waiting)

        # input generators
        generator_method = @stream ? :start_by_stream : :start_by_dir
        gen = Agent[:input_generator].send(
          generator_method, @tuple_space_server, @input_dir
        )
        sleep 0.1 while not(gen.counter > 0)
      end

      # Wakes up tuple space provider process and push my tuple space server to
      # it.
      def start_tuple_space_provider
        @tuple_space_provider = Pione::TupleSpaceProvider.instance
        @tuple_space_provider.add_tuple_space_server(@tuple_space_server)
      end

      def start_workers
        @resource.times do
          Agent[:task_worker].spawn(Global.front, Util.generate_uuid)
        end
      end

      def connect_relay
        Global.relay_tuple_space_server = @tuple_space_server
        @relay_ref = DRbObject.new_with_uri(@relay)
        @relay_ref.__connect
        if Global.show_communication
          puts "you connected the relay: %s" % @relay
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
    end
  end
end
