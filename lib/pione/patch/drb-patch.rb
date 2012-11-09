# @api private
module DRb
  @waiter_table = Pione::Util::WaiterTable.new

  def waiter_table
    @waiter_table
  end
  module_function :waiter_table

  # module DRbProtocol
  #   def open(uri, config, first=true)
  #     @protocol.each do |prot|
  #       begin
  #         return prot.open(uri, config)
  #       rescue DRbBadScheme
  #       rescue DRbConnError
  #         raise($!)
  #       rescue => e
  #         p e
  #         e.backtrace.each do |line|
  #           puts line
  #         end
  #         raise DRbConnError.new("#{uri} - #{$!.inspect}")
  #       end
  #     end
  #     if first && (config[:auto_load] != false)
  #       auto_load(uri, config)
  #       return open(uri, config, false)
  #     end
  #     raise DRbBadURI, 'can\'t parse uri:' + uri
  #   end
  #   module_function :open
  # end

  class DRbConnError
    attr_reader :args
    def initialize(*args)
      super
      @args = args
    end
  end

  class DRbObject
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
      req_id = Util.generate_uuid_int
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
        puts "%s: %s" % [e.class, e.message]
        caller.each {|line| puts "    %s" % line}
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
        stream.write(dump(req_id) +dump(succ) + dump(result, !succ))
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

  class DRbTCPSocket
    def reader_thread
      @thread ||= Thread.new do
        begin
          # loop for receiving reply and waiting the result
          while true
            req_id, succ, result = recv_reply
            DRb.waiter_table.push(req_id, [succ, result])
          end
        rescue DRbConnError => e
          if Global.show_communication
            puts "%s:%s" % [e.class, e.message]
            puts "    %s" % $!.backtrace
          end
        rescue => e
          puts "%s on %s" % [e.inspect, Process.pid]
          puts "    %s" % $!.backtrace
        end
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

    # @api private
    def self.open(remote_uri)
      begin
        conn = nil

        @mutex.synchronize do
          cache = @table[remote_uri]
          if not(cache.nil?)
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
        return succ, result
      end
    end

    alias :orig_close :close

    def close
      if Global.show_communication
        puts "socket closed on %s" % Process.pid
      end
      unless @closed
        @closed = true
        orig_close
      end
    end

    # Sends a request and takes the result from waiter table.
    def send_message(ref, msg_id, arg, block)
      req_id = @protocol.send_request(ref, msg_id, arg, block)
      @protocol.reader_thread
      succ, result = DRb.waiter_table.take(req_id, msg_id, arg)
      return succ, result
    end
  end

  class DRbServer
    class InvokeMethod
      # you can read request id
      attr_reader :req_id

      # perform without setup_message
      def perform
        @result = nil
        @succ = false

        if $SAFE < @safe_level
          info = Thread.current['DRb']
          if @block
            @result = Thread.new {
              Thread.current['DRb'] = info
              $SAFE = @safe_level
              perform_with_block
            }.value
          else
            @result = Thread.new {
              Thread.current['DRb'] = info
              $SAFE = @safe_level
              perform_without_block
            }.value
          end
        else
          if @block
            @result = perform_with_block
          else
            @result = perform_without_block
          end
        end
        @succ = true
        if @msg_id == :to_ary && @result.class == Array
          @result = DRbArray.new(@result)
        end
        return @succ, @result
      rescue StandardError, ScriptError, Interrupt
        @result = $!
        return @succ, @result
      end

      public :setup_message

      # with request id
      def init_with_client
        req_id, obj, msg, argv, block = @client.recv_request
        @req_id = req_id
        @obj = obj
        @msg_id = msg.intern
        @argv = argv
        @block = block
      end

      # Checks whether it can invoke method.
      def ready?
        return false unless @req_id
        return false unless @msg_id
        return false unless @argv
        return true
      end
    end

    def main_loop
      if @protocol.uri =~ /^receiver:/
        main_loop_receiver
      else
        main_loop_others
      end
    end

    def main_loop_core(client)
      @grp.add Thread.current
      Thread.current['DRb'] = { 'client' => client, 'server' => self }
      DRb.mutex.synchronize do
        client_uri = client.uri
        @exported_uri << client_uri unless @exported_uri.include?(client_uri)
      end
      while true do
        invoke_method = InvokeMethod.new(self, client)
        begin
          invoke_method.setup_message
        rescue DRbConnError => e
          client.close
          if Global.show_communication
            puts "closed socket on server side"
            puts "%s: %s" % [e.class, e.message]
            caller.each {|line| puts " "*4 + line}
          end
          break
        end
        Thread.start(invoke_method) do |invoker|
          begin
            @grp.add Thread.current
            Thread.current['DRb'] = { 'client' => client, 'server' => self }
            succ, result = invoker.perform
            if !succ && Global.show_communication
              result.backtrace.each {|x| puts x}
            end
            # req_id
            client.send_reply(invoker.req_id, succ, result) rescue nil
          rescue DRbConnError => e
            client.close
            if Global.show_communication
              puts "error in method invocation thread"
              puts "%s: %s" % [e.class, e.message]
              caller.each {|line| puts " "*4 + line}
            end
          end
        end
      end
    end

    def main_loop_receiver
      main_loop_core(@protocol)

      # stop transceiver
      @thread.kill.join
    end

    # main loop with request id
    def main_loop_others
      Thread.start(@protocol.accept) do |client|
        # relay socket doesn't need request receiver loop because its aim is
        # to get connection only
        unless @protocol.kind_of?(RelaySocket)
          main_loop_core(client)
        else
        end
      end
    end
  end
end
