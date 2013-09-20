module Pione
  module Global
    #
    # synchronization
    #

    # This is global lock for PIONE system.
    define_internal_item(:monitor, Monitor.new)

    #
    # PIONE's process model
    #

    # This is the command object of this process.
    define_internal_item(:command)

    # This is the front server of this process.
    define_internal_item(:front)

    # This process exits with this status.
    define_internal_item(:exit_status, true)

    #
    # user interface
    #

    define_external_item(:color_enabled, true)

    #
    # misc
    #

    define_external_item(:features, "*")

    define_internal_item(:expressional_features) {
      Util.parse_features(Global.features)
    }
  end
end
