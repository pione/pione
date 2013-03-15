module Pione
  module Command
    class PioneClient < FrontOwnerCommand
      use_option_module CommandOption::TaskWorkerOwnerOption
      use_option_module CommandOption::TupleSpaceProviderOwnerOption

      set_program_name("pione-client") do
        [@filename, "-o %s" % @output_uri, @stream ? "--stream" : ""].join(" ")
      end

      set_program_message "Requests to process PIONE document."

      # --input-uri
      define_option('-i URI', '--input=URI', 'set input directory URI') do |uri|
        parsed = URI.parse(uri)
        unless parsed.scheme
          parsed = URI.parse("local:%s" % Pathname.new(uri).expand_path)
        end
        @input_uri = parsed.as_directory
      end

      # --output-uri
      define_option('-o URI', '--output=URI', 'set output directory URI') do |uri|
        @output_uri = URI.parse(uri)
      end

      # --log
      define_option('--log=PATH', 'set log path') do |path|
        @log_path = path
      end

      # --stream
      define_option('--stream', 'turn on stream mode') do
        @stream = true
      end

      # --request-task-worker
      define_option('--request-task-worker=N', 'set request number of task workers') do |n|
        @request_task_worker = n.to_i
      end

      # --params
      define_option('--params="{Var:1,...}"', "set &main:Main rule's parameters") do |str|
        begin
          params = DocumentTransformer.new.apply(
            DocumentParser.new.parameters.parse(str)
          )
          @params.merge!(params)
        rescue Parslet::ParseFailed => e
          puts "invalid parameters: " + str
          Util::ErrorReport.print(e)
          abort
        end
      end

      # --stand-alone
      define_option('--stand-alone', 'turn on stand alone mode') do
        @stand_alone = true
        @without_tuple_space_provider = true
      end

      # --dry-run
      define_option('--dry-run', 'turn on dry run mode') do |b|
        @dry_run = true
      end

      # --relay
      define_option('--relay=URI', 'turn on relay mode and set relay address') do |uri|
        @relay = uri
      end

      define_option('--name=NAME') do |name|
        @name = name
      end

      attr_reader :tuple_space_server
      attr_reader :name

      def initialize
        super()
        @input_uri = nil
        @output_uri = URI.parse("local:./output/")
        @log_path = "log.txt"
        @stream = false
        @params = Parameters.empty
        @dry_run = false
        @task_worker = [Util.core_number - 1, 1].max
        @request_task_worker = 1
        @worker_threads = []
        @stand_alone = false
        @relay = nil
        @filename = "-"
        @without_tuple_space_provider = false
        @features = "^Interactive"
      end

      private

      def validate_options
        unless @task_worker > 0 or (not(@stand_alone) and @task_worker == 0)
          abort("option error: invalid resource size '%s'" % @task_worker)
        end

        if @stream and @input_uri.nil?
          abort("option error: no input URI on stream mode")
        end

        if not(@input_uri.nil?)
          unless @input_uri.pione? and @input_uri.storage?
            abort("opiton error: bad URI scheme '%s'" % @input_uri)
          end
        end
      end

      def create_front
        Front::ClientFront.new(self)
      end

      def prepare
        super

        @filename = ARGF.filename

        @tuple_space_server = TupleSpaceServer.new(
          task_worker_resource: @request_task_worker
        )

        # setup base uri
        case @output_uri.scheme
        when "local"
          FileUtils.makedirs(@output_uri.path)
          @output_uri = @output_uri.absolute
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

        @output_uri = @output_uri.as_directory.to_s
        @tuple_space_server.set_base_uri(@output_uri)
      end

      def start
        read_process_document
        write_tuples
        connect_relay if @relay
        start_agents

        # start tuple space provider with thread
        # the thread is terminated when the client terminated
        unless @without_tuple_space_provider
          @start_tuple_space_provider_thread = Thread.new do
            start_tuple_space_provider
          end
        end

        start_workers
        @agent = Agent[:process_manager].start(@tuple_space_server, @document, @params, @stream)
        @agent.running_thread.join
        terminate
      end

      def terminate
        # kill the thread for starting tuple space provider
        if @start_tuple_space_provider_thread
          if @start_tuple_space_provider_thread.alive?
            @start_tuple_space_provider_thread.kill
          end
        end

        # terminate tuple space provider
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
          generator_method, @tuple_space_server, @input_uri
        )

        # command listener
        @command_listener = Agent[:command_listener].start(@tuple_space_server, self)
      end

      # Wakes up tuple space provider process and push my tuple space server to
      # it.
      def start_tuple_space_provider
        @tuple_space_provider = Pione::TupleSpaceProvider.instance
        @tuple_space_provider.add_tuple_space_server(@tuple_space_server)
      end

      def start_workers
        @task_worker.times do
          Thread.new { Agent[:task_worker].spawn(Global.front, Util.generate_uuid, @features) }
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
