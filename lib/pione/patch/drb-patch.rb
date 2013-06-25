# @api private
module DRb
  def waiter_table
    @waiter_table ||= Pione::Util::WaiterTable.new
  end
  module_function :waiter_table

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

  class DRbMessage
    alias :orig_initialize :initialize

    def initialize(*args)
      @send_request_lock = Mutex.new
      @recv_request_lock = Mutex.new
      @send_reply_lock = Mutex.new
      @recv_reply_lock = Mutex.new
      orig_initialize(*args)
    end

    def send_request(stream, ref, msg_id, arg, b)
      req_id = Util::UUID.generate_int
      if Global.show_communication
        puts "send_request[%s] %s#%s(%s) on PID %s" % [req_id, ref.__drburi, msg_id, arg, Process.pid]
      end
      data = [
        dump(req_id),
        dump(ref.__drbref),
        dump(msg_id.id2name),
        dump(arg.length),
        arg.map{|e|dump(e)}.join(''),
        dump(b)
      ].join('')
      @send_request_lock.synchronize {stream.write(data)}
      return req_id
    rescue => e
      if Global.show_communication
        ErrorReport.print(e)
      end
      raise(DRbConnError, $!.message, $!.backtrace)
    end

    def recv_request(stream)
      if Global.show_communication
        puts "start recv_request on PID %s" % Process.pid
      end
      @recv_request_lock.synchronize do
        req_id = load(stream)
        ref = load(stream)
        msg_id = load(stream)
        argc = load(stream)
        # puts "req_id %s, ref %s, msg_id %s, argc %s" % [req_id, ref, msg_id, argc]
        ro = DRb.to_obj(ref)
        raise(DRbConnError, "too many arguments") if @argc_limit < argc
        argv = Array.new(argc, nil)
        argc.times do |n|
          argv[n] = load(stream)
        end
        block = load(stream)
        if Global.show_communication
          # puts "end recv_request[%s] %s#%s(%s) on %s" % [req_id, ref ? ref.__drburi : "", msg_id, argv, Process.pid]
        end
        return req_id, ro, msg_id, argv, block
      end
    end

    def send_reply(req_id, stream, succ, result)
      if Global.show_communication
        puts "start send_reply[%s] %s on PID %s" % [req_id, result, Process.pid]
        unless succ
          p result
          result.backtrace.each do |line|
            puts line
          end
          p result.args
        end
      end
      @send_reply_lock.synchronize do
        stream.write(dump(req_id) + dump(succ) + dump(result, !succ))
      end
      if Global.show_communication
        puts "end send_reply[%s] %s on PID %s" % [req_id, result, Process.pid]
      end
    rescue
      raise(DRbConnError, $!.message, $!.backtrace)
    end

    def recv_reply(stream)
      if Global.show_communication
        puts "start recv_reply on PID %s" % Process.pid
      end
      @recv_reply_lock.synchronize do
        req_id = load(stream)
        succ = load(stream)
        result = load(stream)
        if Global.show_communication
          puts "end recv_reply[%s] on PID %s" % [req_id, Process.pid]
        end
        return req_id, succ, result
      end
    end
  end

  class ReplyReaderThreadError < RuntimeError
    attr_reader :inner_exception

    def initialize(exception)
      @inner_exception = exception
    end
  end

  class DRbTCPSocket
    # Makes reader thread for receiving unordered replies.
    def reader_thread(watcher)
      @watcher_mutex ||= Mutex.new
      @watchers ||= Set.new
      @watchers << watcher
      @thread ||= Thread.new do
        begin
          # loop for receiving reply and waiting the result
          while true
            req_id, succ, result = recv_reply
            DRb.waiter_table.push(req_id, [succ, result])
          end
        rescue => e
          @watcher_mutex.synchronize do
            @watchers.each do |watcher|
              if watcher.alive?
                watcher.raise(ReplyReaderThreadError.new(e))
              end
            end
            @watchers.delete_if {|watcher| not(watcher.alive?)}
          end
        end
      end
    end

    def remove_reader_thread_watcher(watcher)
      @watcher_mutex ||= Mutex.new
      @watcher_mutex.synchronize do
        @watchers.delete_if {|th| th == watcher}
      end
    end

    # req_id
    def send_reply(req_id, succ, result)
      @msg.send_reply(req_id, stream, succ, result)
    end

    def alive?
      return @socket ? true : false
    end
  end

  class DRbConn
    @table = {}
    @retry = {}

    def self.table
      @table
    end

    def self.clear_table
      @table.values do |val|
        val.close rescue nil
      end
      @table.clear
    end

    # @api private
    def self.open(remote_uri)
      conn = nil

      @mutex.synchronize do
        cache = @table[remote_uri]
        if not(cache.nil?) and cache.alive?
          conn = cache
        else
          if Global.show_communication
            puts "new connection to %s on %s" % [remote_uri, Process.pid] if remote_uri
          end
          conn = self.new(remote_uri) unless conn
        end
        @table[remote_uri] = conn
      end

      succ, result = yield(conn)
      @retry[remote_uri] = 0
      return succ, result
    rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
      @table.delete(remote_uri)
      @retry[remote_uri] ||= 0
      @retry[remote_uri] += 1
      if @retry[remote_uri] < 5
        retry
      else
        raise
      end
    end

    alias :orig_close :close

    def close
      if Global.show_communication
        puts "socket closed on %s" % Process.pid
      end
      unless @closed
        @closed = true
        self.class.table.delete(remote_uri)
        orig_close
      end
    end

    # Sends a request and takes the result from waiter table.
    def send_message(ref, msg_id, arg, block)
      req_id = @protocol.send_request(ref, msg_id, arg, block)
      @protocol.reader_thread(Thread.current)
      succ, result = DRb.waiter_table.take(req_id, msg_id, arg)
      @protocol.remove_reader_thread_watcher(Thread.current)
      return succ, result
    end
  end

  class DRbServer
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

      def initialize(req_id, obj, msg_id, argv, block)
        @req_id = req_id
        @obj = obj
        @msg_id = msg_id.intern
        @argv = argv
        @block = block
      end

      def eval
        @block ? eval_with_block : eval_without_block
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

    class Invoker
      extend Forwardable

      attr_accessor :thread
      def_delegators :@request, :req_id, :obj, :msg_id, :argv, :block

      def initialize(drb_server, client, request)
        @drb_server = drb_server
        @client = client
        @request = request
        check_insecure_method
      end

      # @api private
      def inspect
        "#<Invoker %s#%s(%s)>" % [@request.obj, @request.msg_id, @request.argv]
      end
      alias :to_s :inspect

      # perform without setup_message
      def invoke
        result = safe_invoke
        if @request.msg_id == :to_ary && result.class == Array
          result = DRbArray.new(result)
        end
        return true, result
      rescue StandardError, ScriptError => e
        return false, e
      end

      private

      def check_insecure_method
        @drb_server.check_insecure_method(@request.obj, @request.msg_id)
      end

      def safe_invoke
        if $SAFE < @drb_server.safe_level
          info = Thread.current['DRb']
          Thread.new do
            Thread.current['DRb'] = info
            $SAFE = @drb_server.safe_level
            @request.eval
          end.value
        else
          @request.eval
        end
      end
    end

    class RequestLooper
      def self.start(server, client)
        self.new(server).start(client)
      end

      def initialize(server)
        @server = server
      end

      def start(client)
        Thread.current['DRb'] = {'client' => client, 'server' => @server}
        @server.add_exported_uri(client.uri)

        loop {handle_request(client)}
      end

      private

      def handle_request(client)
        request = ClientRequest.receive(client)
        invoker = Invoker.new(@server, client, request)
        Thread.start(invoker) do |iv|
          Thread.current['DRb'] = {'client' => client, 'server' => @server}
          call_invoker(client, iv)
        end
      rescue DRbConnError => e
        client.close
        if Global.show_communication
          puts "closed socket on server side"
          ErrorReport.print(e)
        end
        raise StopIteration
      end

      def call_invoker(client, invoker)
        # perform invoker with retaining the information
        invoker.thread = Thread.current
        @server.invokers_mutex.synchronize {@server.invokers << invoker}
        succ, result = invoker.invoke
        @server.invokers_mutex.synchronize {@server.invokers.delete(invoker)}
        invoker.thread = nil

        # error report
        if !succ && Global.show_communication
          result.backtrace.each {|x| puts x}
        end

        # send_reply with req_id
        client.send_reply(invoker.req_id, succ, result) rescue nil
      end
    end

    def main_loop
      if @protocol.uri =~ /^receiver:/
        RequestLooper.start(self, @protocol)
        # stop transceiver
        @thread.kill.join
      else
        Thread.start(@protocol.accept) do |client|
          # relay socket doesn't need request receiver loop because its aim is
          # to get connection only
          unless @protocol.kind_of?(RelaySocket)
            RequestLooper.start(self, client)
          end
        end
      end
    end

    attr_reader :invokers
    attr_reader :invokers_mutex

    def initialize(uri=nil, front=nil, config_or_acl=nil)
      if Hash === config_or_acl
        config = config_or_acl.dup
      else
        acl = config_or_acl || @@acl
        config = {
          :tcp_acl => acl
        }
      end

      @config = self.class.make_config(config)

      @protocol = DRbProtocol.open_server(uri, @config)
      @uri = @protocol.uri
      @exported_uri = [@uri]

      @front = front
      @idconv = @config[:idconv]
      @safe_level = @config[:safe_level]

      @grp = ThreadGroup.new
      @thread = run

      # current performing invokers
      @invokers = []
      @invokers_mutex = Mutex.new

      DRb.regist_server(self)
    end

    def add_exported_uri(uri)
      DRb.mutex.synchronize do
        @exported_uri << uri unless @exported_uri.include?(uri)
      end
    end
  end
end
