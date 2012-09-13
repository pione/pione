module Pione
  # Starts finalization process for PIONE system.
  # @return [void]
  def finalize
    # finalize all innocent white objects
    ObjectSpace.each_object(PioneObject) do |obj|
      obj.finalize
    end
    # system exit
    exit
  end
  module_function :finalize

  # Sets signal trap for the system.
  # @return [void]
  def set_signal_trap
    finalizer = Proc.new { finalize }
    Signal.trap(:INT, finalizer)
  end
  module_function :set_signal_trap

  # Ignores all exceptions of the block execution.
  # @yield []
  #   target block
  # @return [void]
  def ignore_exception(&b)
    begin
      b.call
    rescue Exception
      # do nothing
    end
  end

  # Generates UUID.
  # @return [String]
  #   generated UUID string
  def self.generate_uuid
    UUIDTools::UUID.random_create.to_s
  end

  # Returns hostname of the machine.
  # @return [String]
  #   hostname
  def hostname
    Socket.gethostname
  end
  module_function :hostname
end
