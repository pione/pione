module Pione
  module Global
    #
    # system log
    #

    # This is system logger type. Acceptable types are defined in +Log::SystemLogger.of+.
    define_external_item(:system_logger_type) do |item|
      item.desc = "system logger type"
      item.init = :pione
      item.define_updater {|val| val.to_sym}
    end

    # This configures a system logger. See lib/pione/log/system-log.rb.
    define_computed_item(:system_logger, [:system_logger_type]) do |item|
      item.desc = "system logger object"
      item.define_updater do |val|
        if val.kind_of?(Log::SystemLogger)
          val
        else
          Log::SystemLogger.of(Global.system_logger_type).new
        end
      end
    end

    #
    # pione system logger
    #

    # This configures the color of fatal message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_fatal) do |item|
      item.desc = "color of fatal message"
      item.type = :symbol
      item.init = :red
    end

    # This configures the color of error message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_error) do |item|
      item.desc = "color of error message"
      item.type = :symbol
      item.init = :yellow
    end

    # This configures the color of warn message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_warn) do |item|
      item.desc = "color of warn message"
      item.type = :symbol
      item.init = :blue
    end

    # This configures the color of info message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_info) do |item|
      item.desc = "color of info message"
      item.type = :symbol
      item.init = :green
    end

    # This configures the color of debug message for +Log::PioneSystemLogger+
    define_external_item(:pione_system_logger_debug) do |item|
      item.desc = "color of debug message"
      item.type = :symbol
      item.init = :magenta
    end

    #
    # debug
    #

    # This is debug flag that shows PIONE system activities.
    define_internal_item(:debug_system) do |item|
      item.desc = "debug flag that shows PIONE system activities"
      item.type = :boolean
      item.init = false
    end

    # This is debug flag that shows rule engine activities.
    define_internal_item(:debug_rule_engine) do |item|
      item.desc = "debug flag that shows rule engine activities"
      item.type = :boolean
      item.init = false
    end

    # This is debug flag that shows object communications.
    define_internal_item(:debug_communication) do |item|
      item.desc = "debug flag that shows object communications"
      item.type = :boolean
      item.init = false
    end

    # This is debug flag that shows presence notifications.
    define_internal_item(:debug_presence_notification) do |item|
      item.desc = "debug flag that shows presence notifications"
      item.type = :boolean
      item.init = false
    end

    # This is debug flag that shows ignored exceptions.
    define_internal_item(:debug_ignored_exception) do |item|
      item.desc = "debug flag that shows ignored exceptions"
      item.type = :boolean
      item.init = false
    end
  end
end
