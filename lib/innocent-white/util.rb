require 'uuidtools'
require 'socket'

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
  end
end
