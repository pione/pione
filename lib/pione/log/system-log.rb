module Pione
  module Log
    SystemLog = Rootage::Log
    SystemLog.set_logger_block {Global.system_logger}

    # `Log::PioneSystemLogger` is a PIONE original logger. This generates very
    # colorful message for identifiability and detailed informations.
    class PioneSystemLogger < Rootage::Logger
      include DRbUndumped

      attr_accessor :level

      def initialize(out = nil)
        @queue = Queue.new
        @thread = make_writer_thread
        @level = :info
        @lock = Mutex.new
        @out = out
      end

      def fatal(msg, pos=caller(1).first, pid=Process.pid); push(:fatal, msg, pos, pid); end
      def error(msg, pos=caller(1).first, pid=Process.pid); push(:error, msg, pos, pid); end
      def warn (msg, pos=caller(1).first, pid=Process.pid); push(:warn , msg, pos, pid); end
      def info (msg, pos=caller(1).first, pid=Process.pid); push(:info , msg, pos, pid); end
      def debug(msg, pos=caller(1).first, pid=Process.pid); push(:debug, msg, pos, pid); end

      def terminate
        timeout(3) do
          while @thread.alive?
            if @queue.empty? and not(@lock.locked?)
              @thread.kill.join
              break
            else
              sleep 0.1
            end
          end
        end
      rescue Timeout::Error
        # don't use logger here because it is dead at this time
        $stdout.puts("*** system logger has been terminated unsafety, some messages maybe lost ***")
      ensure
        # kill writer thread
        @thread.kill if @thread.alive?
      end

      def queued?
        not(@queue.empty?)
      end

      private

      def level_to_i(level)
        case level
        when :fatal; 0
        when :error; 1
        when :warn ; 2
        when :info ; 3
        when :debug; 4
        end
      end

      def make_writer_thread
        Thread.new do
          while true do
            level, msg, pos, pid, time = @queue.pop
            @lock.synchronize {print(level, msg, pos, pid, time)}
          end
        end
      end

      def push(level, msg, pos, pid)
        if level_to_i(@level) >= level_to_i(level)
          @queue.push([level, msg, pos, pid, Time.now])
        end
      end

      def color_of(level)
        Global.send("pione_system_logger_%s" % level)
      end

      def print(level, msg, pos, pid, time)
        out = @out || $stdout
        if level == :info
          out.puts "%s: %s" % [level.to_s.color(color_of(level)), msg]
        else
          out.puts "%s: %s [%s] (%s, #%s)" % [level.to_s.color(color_of(level)), msg, pos, time.iso8601(3), pid]
        end
      end
    end

    class DelegatableLogger < Rootage::Logger
      include DRbUndumped

      def initialize(logger)
        @logger = logger
      end

      def fatal(msg, pos=caller(1).first, pid=Process.pid)
        send_message(msg, pos, pid) {@logger.fatal(msg, pos, pid)}
      end

      def error(msg, pos=caller(1).first, pid=Process.pid)
        send_message(msg, pos, pid) {@logger.error(msg, pos, pid)}
      end

      def warn(msg, pos=caller(1).first, pid=Process.pid)
        send_message(msg, pos, pid) {@logger.warn(msg, pos, pid)}
      end

      def info(msg, pos=caller(1).first, pid=Process.pid)
        send_message(msg, pos, pid) {@logger.info(msg, pos, pid)}
      end

      def debug(msg, pos=caller(1).first, pid=Process.pid)
        send_message(msg, pos, pid) {@logger.debug(msg, pos, pid)}
      end

      def terminate
        @logger = nil
      end

      private

      def send_message(msg, pos, pid, &block)
        block.call
      rescue Exception
        # print stdout directly if the logger fails
        $stdout.puts("%s (%s) #%s" % [msg, pos, pid])
      end
    end

    #
    # register loggers
    #

    Rootage::Logger.register(:pione, PioneSystemLogger)
  end
end
