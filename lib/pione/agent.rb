module Pione
  module Agent
    # @api private
    @table = Hash.new

    class << self
      # Returns a class corresponding to the agent type.
      # @param [Symbol] type
      #   agent type
      # @return [Pione::Agent::Base]
      #   agent class
      def [](type)
        @table[type]
      end

      # Sets an agent of the system.
      # @param [Pione::Agent::Base] klass
      #   agent class
      # @return [void]
      def set_agent(klass)
        @table[klass.agent_type] = klass
      end
    end
  end
end

#
# load sub files
#

require 'pione/agent/exception'
require 'pione/agent/base'
require 'pione/agent/tuple-space-client'
require 'pione/agent/command-listener'
require 'pione/agent/task-worker'
require 'pione/agent/input-generator'
require 'pione/agent/rule-provider'
require 'pione/agent/logger'
