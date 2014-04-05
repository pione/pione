module Pione
  module Command
    class PioneDiagnosisNotification < BasicCommand
      #
      # command definitions
      #

      define(:name, "notification")
      define(:desc, "Diagnose notification settings")
      define(:front, Front::DiagnosisNotificationFront)

      #
      # options
      #

      option CommonOption.debug
      option CommonOption.color
      option NotificationOption.notification_targets
      option NotificationOption.notification_receivers

      option(:type) do |item|
        item.type  = :string
        item.range = ["transmitter", "receiver", "both"]
        item.long  = "--type"
        item.arg   = "NAME"
        item.desc  = "transmitter, receiver, or both"
        item.init  = "both"
      end

      option(:timeout) do |item|
        item.type    = :positive_integer
        item.long    = "--timeout"
        item.arg     = "N"
        item.desc    = "timeout after N second"
        item.init = 10
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item << :thread_groups
        item << :message
      end

      setup(:thread_groups) do |item|
        item.desc = "Make thread groups"

        item.assign(:transmitting_threads) {ThreadGroup.new}
        item.assign(:receiver_threads) {ThreadGroup.new}
      end

      setup(:message) do |item|
        item.assign(:message) do
          test(transmitter?)
          "The notification target address seems %s: %s"
        end

        item.assign(:message) do
          test(receiver?)
          "The notification receiver address seems %s: %s"
        end

        item.assign(:message) do
          test(both?)
          "The notification target and receiver address seem %s: %s and %s"
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :diagnosis
      end

      execution(:diagnosis) do |item|
        item.desc = "Diagnose notification address settings"

        item.assign(:target_addrs) do
          Global.notification_targets.map{|uri| uri.to_s}
        end

        item.assign(:receiver_addrs) do
          Global.notification_receivers.map{|uri| uri.to_s}
        end

        item.process do
          test(transmitter?)

          Timeout.timeout(model[:timeout]) {transmit_notification}
          Log::SystemLog.info(model[:message] % ["fine", model[:target_addrs]])
        end

        item.process do
          test(receiver?)

          Timeout.timeout(model[:timeout]) {receive_notification}
          Log::SystemLog.info(model[:message] % ["fine", model[:receiver_addrs]])
        end

        item.process do
          test(both?)

          g = ThreadsWait.new
          g.join_nowait(Thread.new {transmit_notification})
          g.join_nowait(Thread.new {receive_notification})
          Timeout.timeout(model[:timeout]) {g.all_waits}
          Log::SystemLog.info(model[:message] % ["fine", model[:target_addrs], model[:receive_addrs]])
        end

        item.exception(Timeout::Error) do
          test(transmitter?)
          cmd.abort(model[:message] % ["bad", model[:target_addrs]])
        end

        item.exception(Timeout::Error) do
          test(receiver?)
          cmd.abort(model[:message] % ["bad", model[:receiver_addrs]])
        end

        item.exception(Timeout::Error) do
          test(both?)
          cmd.abort(msg % ["bad", model[:target_addrs], model[:receive_addrs]])
        end
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |item|
        item << :thread_groups
      end

      termination(:thread_groups) do |item|
        item.desc = "Terminate all threads"

        item.process do
          model[:transmitting_threads].list.each {|thread| thread.terminate}
          model[:receiver_threads].list.each {|thread| thread.terminate}
        end
      end
    end

    class PioneDiagnosisNotificationContext < Rootage::CommandContext
      NOTIFIER = "PIONE_DIAGNOSIS_NOTIFICATION"

      def transmitter?
        model[:type] == "transmitter"
      end

      def receiver?
        model[:type] == "receiver"
      end

      def both?
        model[:type] == "both"
      end

      # Transmit test notification messages to targets repeatedly.
      def transmit_notification
        Global.notification_targets.each do |uri|
          transmitter_id = uri.to_s

          thread = Thread.new do
            # register the current thread to front server
            Thread.current[:transmitter_id] = transmitter_id
            model[:front].register_transmitting_thread(Thread.current)

            # build a notification message
            message = Notification::Message.new(
              NOTIFIER, "TEST", {"front" => model[:front].uri, "transmitter_id" => transmitter_id}
            )

            # create a transmitter
            transmitter = Notification::Transmitter.new(uri)

            # trasmitting loop for "TEST" notifications
            begin
              loop do
                transmitter.transmit(message)
                Log::SystemLog.info('Notification message has been sent to "%s".' % uri)

                sleep 1
              end
            ensure
              transmitter.close
            end
          end

          model[:transmitting_threads].add(thread)
        end

        model[:transmitting_threads].list.each {|thread| thread.join}
      end

      def receive_notification
        Global.notification_receivers.each do |uri|
          thread = Thread.new do
            receiver = Notification::Receiver.new(uri)

            begin
              loop do
                Log::SystemLog.info('Notification receiver is waiting at "%s".' % uri.to_s)
                transmitter_host, message = receiver.receive
                Log::SystemLog.info('Notification has been received from "%s".' % transmitter_host)

                begin
                  DRbObject.new_with_uri(message["front"]).touch(message["transmitter_id"])
                  Log::SystemLog.info('Receiver has touched transmitter at "%s".' % message["front"])
                  break
                rescue Object => e
                  Log::SystemLog.warn(e.message)
                end
              end
            ensure
              receiver.close
            end
          end

          model[:receiver_threads].add(thread)
        end

        model[:receiver_threads].list.each {|thread| thread.join}
      end
    end

    PioneDiagnosisNotification.define(:process_context_class, PioneDiagnosisNotificationContext)

    PioneDiagnosis.define_subcommand("notification", PioneDiagnosisNotification)
  end
end
