module InnocentWhite
  VERSION = 0

  def self.debug_mode(mode = true)
    @debug_mode = true
  end

  def self.debug_mode?
    @debug_mode || false
  end

  def self.finalize
    ObjectSpace.each_object(InnocentWhiteObject) do |obj|
      obj.finalize
    end
    exit
  end

  def self.finalizer
    Proc.new { finalize }
  end

  def self.set_signal_trap
    Signal.trap(:INT, finalizer)
  end
end
