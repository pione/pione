module Pione
  module System
    # Starts finalization process for PIONE system. It collects all pione
    # objects from object space and finalize it.
    # @return [void]
    def finalize
      # finalize all innocent white objects
      ObjectSpace.each_object(PioneObject) do |obj|
        obj.finalize
      end
    end
    module_function :finalize

    # Sets signal trap for the system.
    # @return [void]
    def set_signal_trap
      finalizer = Proc.new { finalize }
      Signal.trap(:INT, finalizer)
    end
    module_function :set_signal_trap

    # Return temporary path of the file.
    #
    # @param filename [String]
    #   the file's name
    # @return [Pathname]
    #  temporary path of the file
    def temporary_path(filename)
      Global.temporary_directory + filename
    end
  end
end
