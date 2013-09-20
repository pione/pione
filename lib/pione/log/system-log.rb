module Pione
  module Log
    module SystemLog
      # Log the fatal message. This level is used when system will go to shutdown.
      def self.fatal(msg, pos=caller(1).first)
        Global.system_logger.fatal(msg, pos)
      end

      # Log the error message.
      def self.error(msg, pos=caller(1).first)
        Global.system_logger.error(msg, pos)
      end

      # Log the warn message.
      def self.warn(msg, pos=caller(1).first)
        Global.system_logger.warn(msg, pos)
      end

      # Log the info message.
      def self.info(msg, pos=caller(1).first)
        Global.system_logger.info(msg, pos)
      end

      # Log the debug message.
      def self.debug(msg, pos=caller(1).first)
        Global.system_logger.debug(msg, pos)
      end

      def self.terminate
        Global.system_logger.terminate
      end
    end

    # SystemLogger is a interface for system logger implementations.
    class SystemLogger
      @logger = {} # logger class table

      # Return logger class of the type.
      def self.of(type)
        @logger[type]
      end

      # Register the logger class with the type.
      def self.register(type, logger_class)
        @logger[type] = logger_class
      end

      # Return the log level.
      def level
        raise NotImplementedError
      end

      # Set the log level.
      def level=(level)
        raise NotImplementedError
      end

      # Log the fatal message.
      def fatal(msg, pos=caller(1).first)
        raise NotImplementedError
      end

      # Log the error message.
      def error(msg, pos=caller(1).first)
        raise NotImplementedError
      end

      # Log the warn message.
      def warn(msg, pos=caller(1).first)
        raise NotImplementedError
      end

      # Log the info message.
      def info(msg, pos=caller(1).first)
        raise NotImplementedError
      end

      # Log the debug message.
      def debug(msg, pos=caller(1).first)
        raise NotImplementedError
      end

      # Terminate the logger.
      def terminate
        raise NotImplementedError
      end

      # Return true if some messages are queued.
      def queued?
        raise NotImplementedError
      end
    end

    # PioneSystemLogger is a PIONE original logger. This generates very colorful
    # message for identifiability and detailed informations.
    class PioneSystemLogger < SystemLogger
      attr_accessor :level

      def initialize(out = $stdout)
        @queue = Queue.new
        @thread = make_writer_thread
        @level = :info
        @out = out
      end

      def fatal(msg, pos=caller(1).first); push(:fatal, msg, pos); end
      def error(msg, pos=caller(1).first); push(:error, msg, pos); end
      def warn (msg, pos=caller(1).first); push(:warn , msg, pos); end
      def info (msg, pos=caller(1).first); push(:info , msg, pos); end
      def debug(msg, pos=caller(1).first); push(:debug, msg, pos); end

      def terminate
        timeout(3) do
          while @thread.alive?
            if @queue.empty?
              @thread.kill.join
              break
            else
              sleep 0.1
            end
          end
        end
      rescue Timeout::Error
        # kill writer thread
        @thread.kill if @thread.alive?

        # don't use logger because it is dead at this time
        @out.puts("*** system logger has been terminated unsafety, some messages maybe lost ***")
      end

      def queued?
        not(@queue.empty?)
      end

      private

      def make_writer_thread
        Thread.new do
          while true do
            level, msg, pos, time = @queue.pop
            print(level, msg, pos, time)
          end
        end
      end

      def push(level, msg, pos)
        @queue.push([level, msg, pos, Time.now])
      end

      def color_of(level)
        Global.send("pione_system_logger_%s" % level)
      end

      def print(level, msg, pos, time)
        if level == :info
          @out.puts "%s: %s" % [level.to_s.color(color_of(level)), msg]
        else
          @out.puts "%s: %s [%s] (%s, #%s)" % [level.to_s.color(color_of(level)), msg, pos, time.iso8601(3), Process.pid]
        end
      end
    end

    # StandardSystemLogger is a logger using Ruby standard Logger.
    class RubyStandardSystemLogger < SystemLogger
      forward! :@logger, :level, :level=

      def initialize(out = $stdout)
        @logger = Logger.new(out)
      end

      def fatal(msg, pos=caller(1).first); @logger.fatal(msg); end
      def error(msg, pos=caller(1).first); @logger.error(msg); end
      def warn (msg, pos=caller(1).first); @logger.warn(msg) ; end
      def info (msg, pos=caller(1).first); @logger.info(msg) ; end
      def debug(msg, pos=caller(1).first); @logger.debug(msg); end

      def terminate
        # ignore
      end

      def queued?
        false
      end
    end

    # SyslogSystemLogger is a logger using syslog("syslog-logger" gem).
    class SyslogSystemLogger < SystemLogger
      forward! :@logger, :level, :level=

      def initialize
        @logger = Logger::Syslog.new('pione')
      end

      def fatal(msg, pos=caller(1).first); @logger.fatal(msg); end
      def error(msg, pos=caller(1).first); @logger.error(msg); end
      def warn (msg, pos=caller(1).first); @logger.warn(msg) ; end
      def info (msg, pos=caller(1).first); @logger.info(msg) ; end
      def debug(msg, pos=caller(1).first); @logger.debug(msg); end

      def terminate
        # ignore
      end

      def queued?
        false
      end
    end

    #
    # register loggers
    #

    SystemLogger.register(:pione, PioneSystemLogger)
    SystemLogger.register(:ruby, RubyStandardSystemLogger)
    SystemLogger.register(:syslog, SyslogSystemLogger)
  end
end
