module Pione
  module Front
    # `DiagnosisNotificationFront` is a front server for diagnosis test about
    # sending notifications.
    class DiagnosisNotificationFront < BasicFront
      LOCK = Mutex.new

      def initialize(cmd)
        super(cmd, Global.diagnosis_notification_front_port_range)
        @transmitting_threads = ThreadGroup.new
      end

      # If the front is touched, notification diagnosis is success.
      #
      # @param transmitter_id [String]
      #   transmitter ID, this is a string of transmitter's target URI
      # @return [void]
      def touch(transmitter_id)
        LOCK.synchronize do
          @transmitting_threads.list.each do |thread|
            if thread[:transmitter_id] == transmitter_id and thread.alive?
              thread.terminate
            end
          end
        end
        return true
      end

      # Register the transmitting thread for test.
      #
      # @param thread [Thread]
      #   a transmitting thread,
      #   see `Pione::Command::PioneDiagnosisNotification`
      # @return [void]
      def register_transmitting_thread(thread)
        LOCK.synchronize {@transmitting_threads.add(thread)}
      end
    end
  end
end
