module Pione
  module Command
    class PioneClient < FrontOwner
      set_program_name("pione-client") do
        [@filename, "-b %s" % @base_uri, @stream ? "--stream" : ""].join(" ")
      end

      define_option('-i dir', '--input-dir=dir') do |dir|
        @input_dir = dir
      end

      define_option('-b uri', '--base-uri=uri', 'base uri') do |uri|
        @base_uri = ::URI.parse(uri)
      end

      define_option('-l path', '--log=path', 'log path') do |path|
        @log_path = path
      end

      define_option('-s', '--stream') do
        @stream = true
      end

      define_option('-r n', '--resource=n') do |n|
        @resource = n.to_i
      end

      define_option('--params="{Var:1,...}"') do |str|
        @params = DocumentTransformer.new.apply(
          DocumentParser.new.parameters.parse(str)
        )
      end

      define_option('--stand-alone') do
        @stand_alone = true
        @without_tuple_space_provider = true
      end

      define_option('--dry-run') do |b|
        @dry_run = true
      end

      define_option('--relay uri') do |uri|
        @relay = uri
      end

      define_option('--without-tuple-space-provider') do
        @without_tuple_space_provider = true
      end

      attr_reader :tuple_space_server

      def initialize
        super()
        @input_dir = nil
        @base_uri = ::URI.parse("local:./output/")
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
          abort("invalid resource size: %s" % @resource)
        end
      end

      def create_front
        Front::ClientFront.new(self)
      end

      def prepare
        @filename = ARGF.filename

        # base uri
        if @base_uri.scheme == "local"
          FileUtils.makedirs(@base_uri.path)
          @base_uri = @base_uri.absolute
        end
        @base_uri = @base_uri.to_s

        @tuple_space_server = TupleSpaceServer.new(
          task_worker_resource: @resource,
          base_uri: @base_uri
        )
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

      def start_tuple_space_provider
        @provider = Pione::TupleSpaceProvider.instance
        @provider.tuple_space_server = @tuple_space_server
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
