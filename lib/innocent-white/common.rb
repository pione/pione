require 'uuidtools'
require 'socket'
require 'digest'
require 'socket'
require 'drb/drb'
require 'rinda/rinda'
require 'rinda/tuplespace'

module InnocentWhite
  # Change debug mode true or not.
  def self.debug_mode=(mode = true)
    @debug_mode = mode
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

  class UnknownVariableException < Exception; end

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

    # Make task_id by input data names.
    def self.task_id(inputs, params)
      # FIXME: inputs.flatten?
      input_names = inputs.flatten.map{|t| t.name}
      is = input_names.join("\000")
      ps = params.join("\000")
      Digest::MD5.hexdigest("#{is}\001#{ps}\001")
    end

    # Make target domain name by module name, inputs, and outputs.
    def self.domain(rule_path, inputs, params)
      "#{rule_path}_#{task_id(inputs, params)}"
    end

    def self.expand_variables(str, variables)
      str.gsub(/\{\$(.+?)\}/) do
        if variables.has_key?($1)
          variables[$1]
        else
          raise UnknownVariableException.new($1)
        end
      end
    end

  end
end

require 'innocent-white/tuple'
require 'innocent-white/document'
require 'innocent-white/tuple-space-server'
