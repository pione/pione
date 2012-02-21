require 'innocent-white/agent'

module InnocentWhite
  module Simulator
    class InputGeneratorMethod
      def generate(&b)
        raise RuntimeError
      end
    end

    class SimpleInputGeneratorMethod < InputGeneratorMethod
      def initialize(name_range, ext, val_range)
        @name_range = name_range
        @ext = ext
        @val_range = val_range
      end
      
      def generate(&b)
        vals = @val_range.to_a
        @name_range.to_a.each_with_index do |basename,i|
          b.call("#{basename}.#{@ext}", vals[i])
        end
      end
    end

    module Agent
      class InputGenerator < InnocentWhite::Agent::Base
        set_agent_type :input_generator

        def initialize(ts_server, generator)
          raise ArgumentError unless generator.kind_of?(InputGeneratorMethod)
          super(ts_server)
          @generator = generator
          start_running
        end

        def run
          @generator.generate do |name, val|
            tuple = Tuple[:data].new(data_type: :raw, name: name, path:"/", raw: val, time: Time.now)
            @tuple_space_server.write(tuple)
            log(:debug, "generate #{name}: #{val}")
          end
          stop
        end
      end
    end
  end

  Agent.set_agent Simulator::Agent::InputGenerator
end
