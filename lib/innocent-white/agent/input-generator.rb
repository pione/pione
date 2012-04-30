require 'innocent-white/common'
require 'innocent-white/agent'
require 'innocent-white/uri'
require 'innocent-white/resource'

module InnocentWhite
  module Agent
    class InputGenerator < InnocentWhite::Agent::Base
      set_agent_type :input_generator

      InputData = Struct.new(:name, :uri)
      DOMAIN = "/input"

      # Base class for generator methods.
      class GeneratorMethod
        def generate
          raise RuntimeError
        end
      end

      # Simple generator based on range and extension.
      class SimpleGeneratorMethod < GeneratorMethod
        def initialize(base_uri, name, name_range, value_range)
          @base_uri = base_uri
          @name = name
          @name_range = name_range.to_enum
          @value_range = value_range.to_enum
        end

        def generate
          name = DataExpr.new(@name).generate(@name_range.next)
          uri = @base_uri + "./input/#{name}"
          Resource[uri].create(@value_range.next)
          InputData.new(name, uri.to_s)
        end
      end

      # Directory based generator.
      class DirGeneratorMethod < GeneratorMethod
        def initialize(dir_path)
          @dir_path = dir_path
          @gen = Dir.open(dir_path).to_enum
        end

        def generate
          name = @gen.next
          path = File.join(@dir_path, name)
          uri = "local:#{File.expand_path(path)}"
          ['.', '..'].include?(name) ? generate : InputData.new(name, uri)
        end
      end

      class StreamGeneratorMethod < GeneratorMethod
        def initialize(dir_path)
          @dir_path = dir_path
          @gen = Dir.open(dir_path).to_enum
        end

        def generate
          name = @gen.next
          path = File.join(@dir_path, name)
          uri = "local:#{File.expand_path(path)}"
          ['.', '..'].include?(name) ? generate : InputData.new(name, uri)
        end
      end

      # Create a input generator agent by simple method.
      def self.start_by_simple(ts_server, *args)
        start(ts_server, SimpleGeneratorMethod.new(ts_server.base_uri, *args))
      end

      # Create a input generator agent by directory method.
      def self.start_by_dir(ts_server, *args)
        start(ts_server, DirGeneratorMethod.new(*args))
      end

      # Create a input generator agent by stream method.
      def self.start_by_stream(ts_server, *args)
        start(ts_server, StreamGeneratorMethod.new(*args))
      end

      define_state :generating
      define_state :stop_iteration

      define_state_transition :initialized => :generating
      define_state_transition :generating => :generating
      define_state_transition :stop_iteration => :terminated

      define_exception_handler StopIteration => :stop_iteration

      attr_reader :generator

      # Initialize the agent.
      def initialize(ts_server, generator)
        raise ArgumentError unless generator.kind_of?(GeneratorMethod)
        super(ts_server)
        @generator = generator
      end

      private

      # State generating generates a data from generator and puts it into tuple
      # space.
      def transit_to_generating
        input = @generator.generate
        write(Tuple[:data].new(domain: DOMAIN, name: input.name, uri: input.uri))
        return input
      end

      # State stop_iteration. StopIteration exception is ignored because it
      # means the input generation was completed.
      def transit_to_stop_iteration(e)
        puts e
        # do nothing
      end

      # Log for generating a input data.
      advise :around, {
        :method => :transit_to_generating,
        :method_options => [:private]
      } do |jp, agent, *args|
        input = jp.proceed
        agent.log do |l|
          l.add_record(agent.agent_type, "action", "generate_input_data")
          l.add_record(agent.agent_type, "uuid", agent.uuid)
          l.add_record(agent.agent_type, "object", input.name)
        end
      end
    end

    set_agent InputGenerator
  end
end
