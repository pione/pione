module Pione
  module Command
    # BasicCommand provides PIONE's basic command structure. PIONE commands have
    # 4 phases: "init", "setup", "execution", "termination". Concrete commands
    # implement some processings as each phases.
    class BasicCommand < Rootage::StandardCommand
      phase(:init) do |seq|
        seq.clear
        seq << Rootage::InitAction.signal_trap
        seq << Rootage::InitAction.option
        seq << Rootage::InitAction.argument
        seq << Rootage::InitAction.program_name
        seq << InitAction.front
        seq << Rootage::InitAction.program_name # for showing front address
      end

      # Return the program name with the front URI and the parent's front URI.
      def program_name
        additions = []

        # front server URI
        if model[:front]
          additions << "front: %s" % model[:front].uri
        end

        # parent front server URI
        if model[:parent_front]
          additions << "parent: %s" % model[:parent_front].uri
        end

        if additions.empty?
          name
        else
          "%s (%s)" % [name, additions.join(", ")]
        end
      end

      # Exit the running command and return failure status. Note that this
      # method enters termination phase before it exits.
      def abort(msg_or_exception, pos=caller(1).first)
        # hide the message because some option errors are meaningless
        if msg_or_exception.is_a?(HideableOptionError)
          Log::Debug.system(msg_or_exception.message, pos)
        end

        super
      end

      private

      def exit_process
        model[:front].terminate if model[:front]
        Global.system_logger.terminate
      end
    end
  end
end
