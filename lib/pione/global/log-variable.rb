module Pione
  module Global
    #
    # system log
    #

    # This is system logger type. Acceptable types are defined in +Log::SystemLogger.of+.
    define_external_item(:system_logger_type, :pione)

    # This configures a system logger. See lib/pione/log/system-log.rb.
    define_computed_item(:system_logger, [:system_logger_type]) do
      Log::SystemLogger.of(Global.system_logger_type).new
    end

    #
    # pione system logger
    #

    # This configures the color of fatal message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_fatal, :red)

    # This configures the color of error message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_error, :yellow)

    # This configures the color of warn message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_warn, :blue)

    # This configures the color of info message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_info, :green)

    # This configures the color of debug message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_debug, :magenta)

    #
    # debug
    #

    # This is debug flag that shows PIONE system activities.
    define_internal_item(:debug_system, false)

    # This is debug flag that shows rule engine activities.
    define_internal_item(:debug_rule_engine, false)

    # This is debug flag that shows object communications.
    define_internal_item(:debug_communication, false)

    # This is debug flag that shows presence notifications.
    define_internal_item(:debug_presence_notification, false)

    # This is debug flag that shows ignored exceptions.
    define_internal_item(:debug_ignored_exception, false)
  end
end
