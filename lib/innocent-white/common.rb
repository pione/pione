require 'uuidtools'
require 'socket'
require 'digest'

module InnocentWhite
  # Change debug mode true or not.
  def self.debug_mode(mode = true)
    @debug_mode = true
  end

  # Return true if the system is debug mode.
  def self.debug_mode?
    @debug_mode ||= false
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

  # Basic object class of innocent-white system.
  class InnocentWhiteObject
    def uuid
      @__uuid__ ||= Util.uuid
    end

    # Finalize the object.
    def finalize
      # none
    end
  end

  # Utility functions for innocent-white system.
  module Util
    # Set signal trap for the system.
    def self.set_signal_trap
      finalizer = Proc.new { finalize }
      Signal.trap(:INT, finalizer)
    end

    # Generate UUID.
    def self.uuid
      UUIDTools::UUID.random_create.to_s
    end

    # Ignore all exceptions of the block execution.
    def self.ignore_exception(&b)
      begin
        b.call
      rescue Exception
        # do nothing
      end
    end

    # Return hostname of the machine.
    def self.hostname
      Socket.gethostname
    end

    # Make taskid by input and output data names.
    def self.taskid(inputs, outputs)
      i = inputs.join("\000")
      o = outputs.join("\000")
      Digest::MD5.hexdigest("#{i}\001#{o}\001")
    end

    # Make target domain name by module name, inputs, and outputs.
    def self.target_domain(modname, inputs, outputs)
      modname + taskid(inputs, outputs)
    end

    def self.expand_variables(str, variables)
      str.gsub(/\{\$(.+?)\}/){variables[$1]}
    end

  end
end
