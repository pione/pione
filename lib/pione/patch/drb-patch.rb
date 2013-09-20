module Pione
  module DRbPatch
    #
    # special protocol
    #

    # Return waiter table for the aim that clients enable to wait to receive the
    # reply.
    def self.waiter_table
      @waiter_table ||= Pione::Util::WaiterTable.new
    end

    # ReplyReaderError is raised when reply reader happens something error. See
    # +ReplyReader+ class.
    class ReplyReaderError < RuntimeError
      attr_reader :inner_exception

      def initialize(exception)
        @inner_exception = exception
      end
    end

    class ReplyReader
      def initialize
        @watcher_lock = Mutex.new
        @watchers = Set.new
      end

      def start(protocol)
        @thread ||= Thread.new do
          begin
            # loop for receiving reply and waiting the result
            while true
              # receive a replay
              req_id, succ, result = protocol.recv_reply
              # register it to waiter table
              DRbPatch.waiter_table.push(req_id, [succ, result])
            end
          rescue => e
            @watcher_lock.synchronize do
              # pass the exception to watchers
              @watchers.each do |watcher|
                Log::Debug.communication("connection error happened in receiving reply.")
                Log::Debug.communication(e)
                watcher.raise(ReplyReaderError.new(e)) if watcher.alive?
              end

              # remove dead watchers
              @watchers.delete_if {|watcher| not(watcher.alive?)}
            end
          end
        end
      end

      # Makes reader thread for receiving unordered replies.
      def add_watcher(watcher)
        @watcher_lock.synchronize do
          @watchers << watcher
        end
      end

      # Remove the request reader thread watcher.
      def remove_watcher(watcher)
        @watcher_lock.synchronize do
          @watchers.delete_if {|th| th == watcher}
        end
      end
    end

    # +PioneTCPSocket+ is a reply reader thread extension for standard
    # +DRbTCPSocket+.
    class PioneTCPSocket < DRb::DRbTCPSocket
      def initialize(uri, soc, config={})
        super
        @reply_reader = ReplyReader.new
      end

      # Send the request from client to server.
      def send_request(ref, msg_id, arg, b)
        # set watcher
        @reply_reader.add_watcher(Thread.current)

        # send the request
        req_id = @msg.send_request(stream, ref, msg_id, arg, b)

        # start reply reader
        @reply_reader.start(self)

        # wait the reply by using watier table
        succ, result = Pione::DRbPatch.waiter_table.take(req_id, msg_id, arg)

        # remove watcher
        @reply_reader.remove_watcher(Thread.current)

        return succ, result
      end

      # Send the reply with request id. Note: this overrides original +send_rely+.
      def send_reply(req_id, succ, result)
        @msg.send_reply(req_id, stream, succ, result)
      end

      # Return true if connection socket exists.
      def alive?
        return (@socket and not(@socket.closed?))
      end
    end

    # +PioneDRbMessage+ is a special protocol for +PioneTCPSocket+.
    class PioneDRbMessage < DRb::DRbMessage
      def initialize(*args)
        @send_request_lock = Mutex.new
        @recv_request_lock = Mutex.new
        @send_reply_lock = Mutex.new
        @recv_reply_lock = Mutex.new
        super
      end

      # Send a request to the stream. This is different from original at the
      # point that patched version has request id.
      def send_request(stream, ref, msg_id, arg, b)
        # generate a new request id
        req_id = Util::UUID.generate_int

        # show debug message
        Log::Debug.communication do
          "client sends a request %s#%s (fd: %s, req_id: %s)" % [ref.__drburi, msg_id, stream.to_i, req_id]
        end

        # make a dumped request sequece(request id, ref, msg_id, argc, argv, b)
        data = [
          req_id, ref.__drbref, msg_id.id2name, arg.length, *arg, b
        ].map{|elt| dump(elt)}.join('')

        @send_request_lock.synchronize {stream.write(data)}

        return req_id
      rescue => e
        Log::Debug.communication "following error happened while we send request"
        Log::Debug.communication e
        raise DRb::DRbConnError.new, $!.message, $!.backtrace
      end

      # Receive request from the stream. See +ClientReuqest+.
      def recv_request(stream)
        Log::Debug.communication "server tries to receive a request... (fd: %s)" % stream.to_i

        @recv_request_lock.synchronize do
          # read requst id, object id, method name, and arguments size
          req_id = load(stream)
          ref = load(stream)
          msg_id = load(stream)
          argc = load(stream)

          Log::Debug.communication do
            "server received a request (fd: %s, req_id: %s, ref: %s, msg_id: %s)" % [stream.to_i, req_id, ref.to_s, msg_id]
          end

          # check arguement size
          raise DRb::DRbConnError.new("too many arguments") if @argc_limit < argc

          ro = nil
          available = true

          # refer to object
          begin
            ro = DRb.to_obj(ref)
          rescue RangeError => e
            Log::Debug.system("bad object id \"%s\" is referred (msg_id: %s)" % [ref, msg_id])
            available = false
          end

          # build arguments
          argv = Array.new(argc, nil)
          argc.times {|n| argv[n] = load(stream)}

          # read block
          block = load(stream)

          return req_id, ro, msg_id, argv, block, available
        end
      end

      # Send the reply.
      def send_reply(req_id, stream, succ, result)
        Log::Debug.communication {
          "server sends a reply (fd: %s, req_id: %s, result: %s)" % [stream.to_i, req_id, result]
        }

        # build a reply data
        data = dump(req_id) + dump(succ) + dump(result, !succ)

        @send_reply_lock.synchronize {stream.write(data)}
      rescue
        raise DRb::DRbConnError, $!.message, $!.backtrace
      end

      # Receive a reply(request id, succ, and result) from the stream.
      def recv_reply(stream)
        Log::Debug.communication do
          "client tries to receive a reply... (fd: %s)" % stream.to_i
        end

        @recv_reply_lock.synchronize do
          req_id = load(stream)
          succ = load(stream)
          result = load(stream)

          Log::Debug.communication(
            "client received a reply (fd: %s, req_id: %s)" % [stream.to_i, req_id]
          )

          return req_id, succ, result
        end
      end
    end

    # +PioneDRbConn+ provides connections to +DRb::DRbObject+. This class is
    # different from original +DRbConn+ at the point of connection reuse.
    class PioneDRbConn < DRb::DRbConn
      @cache = {} # connection table
      @retry = {} # retrial counter
      @mutex = Mutex.new # same as original's

      class << self
        attr_reader :cache

        # Clear connection cache table.
        def clear_cache
          @cache.values {|connection| connection.close rescue nil}
          @cache.clear
        end

        # Open a remote URI. This method reuse connection if the URI is cached.
        def open(remote_uri)
          conn = nil

          @mutex.synchronize do
            cache = @cache[remote_uri]

            # get connection
            if not(cache.nil?) and cache.alive?
              conn = cache # use cached connection
            else
              conn = self.new(remote_uri) # create a new connection
              Log::Debug.communication "client created a new connection to %s" % remote_uri.inspect
            end
            @cache[remote_uri] = conn
          end

          succ, result = yield(conn)
          @retry[remote_uri] = 0
          return succ, result
        rescue DRb::DRbConnError, ReplyReaderError, Errno::ECONNREFUSED => e
          Log::Debug.communication "client failed to open a connection to %s." % remote_uri
          @mutex.synchronize do
            if @cache[remote_uri]
              @cache[remote_uri].close
              @cache.delete(remote_uri)
            end
            @retry[remote_uri] ||= 0
            @retry[remote_uri] += 1
          end
          if @retry[remote_uri] < 6
            sleep 0.1
            retry
          else
            raise
          end
        end
      end

      # Close the client-to-server socket.
      def close
        Log::Debug.communication("client closed the socket")
        unless @closed
          @closed = true
          self.class.cache.delete(@uri)
          super
        end
      end

      # Send the message from client to server.
      def send_message(ref, msg_id, arg, block)
        @protocol.send_request(ref, msg_id, arg, block)
      end
    end

    #
    # special server
    #

    # BadRequestError is raised when the object id requested by client is
    # unknonw in server.
    class BadRequestError < StandardError
    end

    # ClientRequest represents client's requests.
    class ClientRequest
      def self.receive(client)
        self.new(*client.recv_request)
      end

      attr_reader :req_id
      attr_reader :obj
      attr_reader :msg_id
      attr_reader :argv
      attr_reader :block
      attr_reader :available

      def initialize(req_id, obj, msg_id, argv, block, available)
        @req_id = req_id
        @obj = obj
        @msg_id = msg_id.intern
        @argv = argv
        @block = block
        @available = available
      end

      def eval
        if @available
          @block ? eval_with_block : eval_without_block
        else
          raise BadRequestError
        end
      end

      private

      # Checks whether it can invoke method.
      def valid?
        return false unless @req_id
        return false unless @msg_id
        return false unless @argv
        return true
      end

      def eval_without_block
        if Proc === @obj && @msg_id == :__drb_yield
          ary = @argv.size == 1 ? @argv : [@argv]
          ary.map(&@obj)[0]
        else
          @obj.__send__(@msg_id, *@argv)
        end
      end

      def block_yield(x)
        if x.size == 1 && x[0].class == Array
          x[0] = DRbArray.new(x[0])
        end
        @block.call(*x)
      end

      def eval_with_block
        @obj.__send__(@msg_id, *@argv) do |*x|
          jump_error = nil
          begin
            block_value = block_yield(x)
          rescue LocalJumpError
            jump_error = $!
          end
          if jump_error
            case jump_error.reason
            when :break
              break(jump_error.exit_value)
            else
              raise jump_error
            end
          end
          block_value
        end
      end
    end

    class RequestInvoker
      def initialize(server, client, request)
        @server = server
        @client = client
        @request = request
        check_insecure_method
      end

      def invoke
        # evaluate request
        succ, result = execute_request

        # send_reply with req_id
        begin
          @client.send_reply(@request.req_id, succ, result)
        rescue => e
          Log::Debug.system("it happened communication failure in sending reply(req_id: %s): %s" % [@request.req_id, e.message])
        end
      end

      private

      # perform without setup_message
      def execute_request
        result = eval_request
        if @request.msg_id == :to_ary && result.class == Array
          result = DRbArray.new(result)
        end
        return true, result
      rescue StandardError, ScriptError => e
        return false, e
      end

      def check_insecure_method
        @server.check_insecure_method(@request.obj, @request.msg_id)
      end

      def eval_request
        $SAFE < @server.safe_level ? safe_eval_request : unsafe_eval_request
      end

      # Execute the request within sandbox.
      def safe_eval_request
        info = Thread.current['DRb']
        Thread.new do
          # import DRb info to the sandbox
          Thread.current['DRb'] = info

          # make sandbox
          $SAFE = @drb_server.safe_level

          # invoke request
          unsafe_request_invoke
        end.value
      end

      # Execute the request.
      def unsafe_eval_request
        @request.eval
      end
    end

    # RequestLooper is a receiver of client request. This is different from
    # standard DRb's +main_loop+ at the point that this method doesn't need to
    # wait finishing evaluation of request and reply.
    class RequestLooper
      def initialize(server)
        @server = server
      end

      def start(client)
        loop {handle_client_request(client)}
      end

      private

      def handle_client_request(client)
        # take request from client
        request = ClientRequest.receive(client)

        # run invoker
        invoker = RequestInvoker.new(@server, client, request)
        @server.invoker_threads.add(Thread.new{invoker.invoke})
      rescue DRb::DRbConnError => e
        Log::Debug.communication("server was disconnected from client because of connection error")
        client.close
        raise StopIteration
      end
    end

    class PioneDRbServer < DRb::DRbServer
      attr_reader :invoker_threads

      def initialize(uri=nil, front=nil, config_or_acl=nil)
        # current performing invokers
        @invoker_threads = ThreadGroup.new

        super
      end

      def main_loop
        if @protocol.uri =~ /^receiver:/
          RequestLooper.start(self, @protocol)
          @thread.kill.join # stop transceiver
        else
          Thread.start(@protocol.accept) do |client|
            # relay socket doesn't need request receiver loop because its aim is
            # to get connection only
            unless @protocol.kind_of?(Pione::Relay::RelaySocket)
              # set DRb info to current thread
              Thread.current['DRb'] = {'client' => client, 'server' => self}

              # add exported uri
              DRb.mutex.synchronize do
                client_uri = client.uri
                @exported_uri << client_uri unless @exported_uri.include?(client_uri)
              end

              # start request loop
              RequestLooper.new(self).start(client)
            end
          end
        end

        def stop_service
          # stop invokers
          @invoker_threads.list.each {|thread| thread.kill.join}

          # stop main loop etc.
          super
        end
      end
    end
  end
end

# @api private
module DRb
  class DRbConnError
    attr_reader :args

    def initialize(*args)
      super
      @args = args
    end
  end

  class DRbObject
    # Creates fake connection for relay.
    def __connect
      DRbConn.open(@uri) {}
    end
  end

  # change default protocol
  module DRbProtocol
    @protocol.delete(DRbTCPSocket)
    add_protocol(Pione::DRbPatch::PioneTCPSocket)
  end

  # replace some classes
  __verbose__ = $VERBOSE
  $VERBOSE = nil
  # patch DRbConn for special protocol
  const_set :DRbConn, Pione::DRbPatch::PioneDRbConn
  # patch DRbMessage for special protocol
  const_set :DRbMessage, Pione::DRbPatch::PioneDRbMessage
  # patch for threaded request invocations
  const_set :DRbServer, Pione::DRbPatch::PioneDRbServer
  $VERBOSE = __verbose__
end

