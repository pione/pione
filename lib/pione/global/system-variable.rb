module Pione
  module Global
    #
    # synchronization
    #

    # This is global lock for PIONE system.
    define_internal_item(:monitor) do |item|
      item.desc = "global lock for PIONE system"
      item.init = Monitor.new
    end

    #
    # PIONE's process model
    #

    define_internal_item(:parent) do |item|
      item.desc = "front of parent process"
    end

    define_internal_item(:notification_recipient) do |item|
      item.desc = "notification recipient of this process"
    end

    #
    # user interface
    #

    define_external_item(:color_enabled) do |item|
      item.desc = "availability of color mode"
      item.init = true
      item.post do |val|
        Sickill::Rainbow.enabled = val
      end
    end

    #
    # misc
    #

    define_external_item(:features) do |item|
      item.desc = "string of features for this system"
      item.init = "*"
    end

    define_computed_item(:expressional_features, [:features]) do |item|
      item.desc = "expression of features for this system"
      item.define_updater {Util.parse_features(Global.features)}
    end

    define_external_item(:file_sliding) do |item|
      item.desc = "enable/disable to slide files in file server"
      item.init = true
    end
  end
end
