module Pione
  module Log
    module SystemLog
      # Log the fatal message.
      #
      # @param msg [String]
      #   the fatal message
      def fatal(msg)
        Global.system_logger.fatal(msg)
      end
      module_function :fatal

      # Log the error message.
      #
      # @param msg [String]
      #   the error message
      def error(msg)
        Global.system_logger.error(msg)
      end
      module_function :error

      # Log the warn message.
      #
      # @param msg [String]
      #   the warn message
      def warn(msg)
        Global.system_logger.warn(msg)
      end
      module_function :warn

      # Log the info message.
      #
      # @param msg [String]
      #   the info message
      def info(msg)
        Global.system_logger.info(msg)
      end
      module_function :info

      # Log the debug message.
      #
      # @param msg [String]
      #   the debug message
      def debug(msg)
        Global.system_logger.debug(msg)
      end
      module_function :debug
    end

    class SystemLogger
      # Log the fatal message.
      #
      # @param msg [String]
      #   the fatal message
      def fatal(msg)
        raise NotImplementedError
      end

      # Log the error message.
      #
      # @param msg [String]
      #   the error message
      def error(msg)
        raise NotImplementedError
      end

      # Log the warn message.
      #
      # @param msg [String]
      #   the warn message
      def warn(msg)
        raise NotImplementedError
      end

      # Log the info message.
      #
      # @param msg [String]
      #   the info message
      def info(msg)
        raise NotImplementedError
      end

      # Log the debug message.
      #
      # @param msg [String]
      #   the debug message
      def debug(msg)
        raise NotImplementedError
      end
    end

    # StandardSystemLogger is a logger using Ruby standard Logger.
    class StandardSystemLogger
      forward! :@logger, :fatal, :error, :warn, :info, :debug

      def initialize(out)
        @logger = Logger.new(out)
      end
    end

    # class SyslogSystemLogger
    #   forward @fatal, :fatal, :call
    #   forward @error, :error, :call
    #   forward @warn, :warn, :call
    #   forward @info, :info, :call
    #   forward @debug, :debug, :call

    #   def initialize
    #     @logger = Proc.new{|level, msg| Syslog.open("pione") {|syslog| syslog.log(pri, msg)} }.curry
    #     @fatal = @logger.call(Syslog::LOG_ALERT)
    #     @error = @logger.call(Syslog::LOG_ERR)
    #     @warn = @logger.call(Syslog::LOG_WARNING)
    #     @info = @logger.call(Syslog::LOG_INFO)
    #     @debug = @logger.call(Sysmlog::LOG_DEBUG)
    #   end
    # end
  end
end
