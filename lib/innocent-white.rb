module InnocentWhite
  VERSION = 0

  # Change debug mode true or not.
  def self.debug_mode(mode = true)
    @debug_mode = true
  end

  # Return true if the system is debug mode.
  def self.debug_mode?
    @debug_mode || false
  end

  # Start finalization process for InnocentWhite world.
  def self.finalize
    # finalize all innocent white objects
    ObjectSpace.each_object(InnocentWhiteObject) do |obj|
      obj.finalize
    end
    # system exit
    exit
  end

  # Set signal trap for the system.
  def self.set_signal_trap
    finalizer = Proc.new { finalize }
    Signal.trap(:INT, finalizer)
  end
end
