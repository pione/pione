module Pione
  module Global
    define_internal_item(:diagnosis_notification_front_start_port) do |item|
      item.desc = "start port number for front server of `pione diagnosis notification`"
      item.init = 1024
    end

    define_internal_item(:diagnosis_notification_front_end_port) do |item|
      item.desc = "end port number for front server of `pione diagnosis notification`"
      item.init = 9999
    end

    define_computed_item(
      :diagnosis_notification_front_port_range,
      [:diagnosis_notification_front_start_port, :diagnosis_notification_front_end_port]
    ) do |item|
      item.desc = "port number for front server of `pione diagnosis notification`"
      item.define_updater do
        start_port = Global.diagnosis_notification_front_start_port
        end_port = Global.diagnosis_notification_front_end_port

        Range.new(start_port, end_port)
      end
    end
  end
end
