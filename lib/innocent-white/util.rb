require 'uuidtools'
require 'socket'
require 'digest'

module InnocentWhite
  module Util

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

    # make taskid by input and output data names
    def make_taskid(inputs, outputs)
      i = inputs.join("\000")
      o = outputs.join("\000")
      Digest::MD5.digest("#{i}\001#{o}\001")
    end
  end
end
