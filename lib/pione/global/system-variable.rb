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

    # This is the command object of this process.
    define_internal_item(:command) do |item|
      item.desc = "command object of this process"
    end

    # This is the front server of this process.
    define_internal_item(:front) do |item|
      item.desc = "front object of this process"
    end

    # This process exits with this status.
    define_internal_item(:exit_status) do |item|
      item.desc = "exit status of this process"
      item.init = true
    end

    #
    # user interface
    #

    define_external_item(:color_enabled) do |item|
      item.desc = "availability of color mode"
      item.init = true
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

    define_external_item(:no_file_sliding) do |item|
      item.desc = "Disable to slide files in file server"
      item.init = false
    end
  end
end
