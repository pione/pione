module Rootage
  module Log
    # Log the fatal message. This level is used when system will go to shutdown.
    def self.fatal(msg, pos=caller(1).first, pid=Process.pid)
      logger.fatal(msg, pos, pid) if logger
    end

    # Log the error message.
    def self.error(msg, pos=caller(1).first, pid=Process.pid)
      logger.error(msg, pos, pid) if logger
    end

    # Log the warn message.
    def self.warn(msg, pos=caller(1).first, pid=Process.pid)
      logger.warn(msg, pos, pid) if logger
    end

    # Log the info message.
    def self.info(msg, pos=caller(1).first, pid=Process.pid)
      logger.info(msg, pos, pid) if logger
    end

    # Log the debug message.
    def self.debug(msg, pos=caller(1).first, pid=Process.pid)
      logger.debug(msg, pos, pid) if logger
    end

    # Return the logger.
    def self.logger
      @logger.call
    end

    # Get a logger block to extract a logger object.
    def self.get_logger_block
      @logger
    end

    # Set logger to use in `Log` interface.
    def self.set_logger_block(&block)
      @logger = block
    end

    # Terminate the logger.
    def self.terminate
      logger.terminate if logger
    end
  end

  # `Logger` is a interface for system logger implementations.
  class Logger
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
    def fatal(msg, pos=caller(1).first, pid=Process.pid)
      raise NotImplementedError
    end

    # Log the error message.
    def error(msg, pos=caller(1).first, pid=Process.pid)
      raise NotImplementedError
    end

    # Log the warn message.
    def warn(msg, pos=caller(1).first, pid=Process.pid)
      raise NotImplementedError
    end

    # Log the info message.
    def info(msg, pos=caller(1).first, pid=Process.pid)
      raise NotImplementedError
    end

    # Log the debug message.
    def debug(msg, pos=caller(1).first, pid=Process.pid)
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

  # `NullLogger` is a logger that ignores all messages.
  class NullLogger < Logger
    attr_accessor :level

    def initialize
      @level = :info
    end

    def fatal(msg, pos=caller(1).first, pid=Process.pid); end
    def error(msg, pos=caller(1).first, pid=Process.pid); end
    def warn (msg, pos=caller(1).first, pid=Process.pid); end
    def info (msg, pos=caller(1).first, pid=Process.pid); end
    def debug(msg, pos=caller(1).first, pid=Process.pid); end

    def terminate
      # ignore
    end

    def queued?
      false
    end
  end

  # `RubyStandardLogger` is a logger using Ruby standard Logger.
  class RubyStandardLogger < Logger
    def initialize(out = $stdout)
      @logger = ::Logger.new(out)
    end

    def level
      case @logger.level
      when ::Logger::FATAL
        :fatal
      when ::Logger::ERROR
        :error
      when ::Logger::WARN
        :warn
      when ::Logger::INFO
        :info
      when ::Logger::DEBUG
        :debug
      else
        raise UnknownLogLevel.new(self.class, :level, @logger.level)
      end
    end

    def level=(lv)
      case lv
      when :fatal
        @logger.level = ::Logger::FATAL
      when :error
        @logger.level = ::Logger::ERROR
      when :warn
        @logger.level = ::Logger::WARN
      when :info
        @logger.level = ::Logger::INFO
      when :debug
        @logger.level = ::Logger::DEBUG
      else
        raise UnknownLogLevel.new(self.class, :level=, lv)
      end
    end

    def fatal(msg, pos=caller(1).first, pid=Process.pid); @logger.fatal(msg); end
    def error(msg, pos=caller(1).first, pid=Process.pid); @logger.error(msg); end
    def warn (msg, pos=caller(1).first, pid=Process.pid); @logger.warn(msg) ; end
    def info (msg, pos=caller(1).first, pid=Process.pid); @logger.info(msg) ; end
    def debug(msg, pos=caller(1).first, pid=Process.pid); @logger.debug(msg); end

    def terminate
      # ignore
    end

    def queued?
      false
    end
  end

  # `SyslogLogger` is a logger using syslog("syslog-logger" gem).
  class SyslogLogger < Logger
    forward! :@logger, :level

    def initialize
      @logger = ::Logger::Syslog.new('pione')
    end

    def level=(lv)
      case lv
      when :fatal, :error, :warn, :info, :debug
        @logger.level = lv
      else
        raise UnknownLogLevel.new(self.class, :level=, lv)
      end
    end

    def fatal(msg, pos=caller(1).first, pid=Process.pid); @logger.fatal(msg); end
    def error(msg, pos=caller(1).first, pid=Process.pid); @logger.error(msg); end
    def warn (msg, pos=caller(1).first, pid=Process.pid); @logger.warn(msg) ; end
    def info (msg, pos=caller(1).first, pid=Process.pid); @logger.info(msg) ; end
    def debug(msg, pos=caller(1).first, pid=Process.pid); @logger.debug(msg); end

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

  Logger.register(:null, NullLogger)
  Logger.register(:ruby, RubyStandardLogger)
  Logger.register(:syslog, SyslogLogger)
end
