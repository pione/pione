require 'innocent-white/agent'

module InnocentWhite
  module Simulator
    module Agent
      class InputGenerator < InnocentWhite::Agent::Base
        set_agent_type :input_generator

        def initialize(ts_server, range, ext)
          raise ArgumentError unless range.respond_to?(:to_a)
          super(ts_server)
          @range = range
          @ext = ext
          start_running
        end

        def data_tuple(basename)
          name = filename(basename)
          Tuple[:data].new(name: name, path:"/", time: Time.now)
        end

        def filename(basename)
          "#{basename}.#{@ext}"
        end

        def run
          @range.to_a.each do |basename|
            tuple = data_tuple(basename)
            @tuple_space_server.write(tuple)
          end
          stop
        end
      end
    end
  end

  Agent.set_agent Simulator::Agent::InputGenerator
end
