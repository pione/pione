require 'innocent-white/common'
require 'innocent-white/uri'
require 'innocent-white/resource'

module InnocentWhite
  module Agent
    class InputGenerator < TupleSpaceClient
      set_agent_type :input_generator

      InputData = Struct.new(:name, :uri, :time)
      DOMAIN = "/input"

      # Base class for generator methods.
      class GeneratorMethod
        def initialize(ts_server)
          @tuple_space_server = ts_server
        end

        def now
          @tuple_space_server.now
        end

        def generate
          raise RuntimeError
        end

        def stream?
          return false
        end
      end

      # Simple generator based on range and extension.
      class SimpleGeneratorMethod < GeneratorMethod
        def initialize(ts_server, base_uri, name, name_range, value_range)
          super(ts_server)
          @base_uri = base_uri
          @name = name
          @name_range = name_range.to_enum
          @value_range = value_range.to_enum
        end

        def generate
          name = DataExpr.new(@name).generate(@name_range.next)
          uri = @base_uri + "./input/#{name}"
          Resource[uri].create(@value_range.next)
          InputData.new(name, uri.to_s, now)
        end
      end

      # Directory based generator.
      class DirGeneratorMethod < GeneratorMethod
        def initialize(ts_server, dir_path)
          super(ts_server)
          @dir_path = dir_path
          @gen = Dir.open(@dir_path).to_enum
        end

        def generate
          name = @gen.next
          path = File.join(@dir_path, name)
          uri = "local:#{File.expand_path(path)}"
          if ['.', '..'].include?(name)
            generate
          else
            InputData.new(name, uri, File.mtime(path))
          end
        end
      end

      # StreamGeneratorMethod handles stream inputs.
      class StreamGeneratorMethod < GeneratorMethod
        def initialize(ts_server, dir_path)
          @dir_path = dir_path
          @table = Hash.new
          init
        end

        def generate
          name = @gen.next
          path = File.join(@dir_path, name)
          mtime = File.mtime(path)
          if generate_new_file?(name, mtime)
            @table[name] = mtime
            uri = "local:#{File.expand_path(path)}"
            return InputData.new(name, uri, mtime)
          else
            return nil
          end
        end

        # Initialize generator.
        def init
          @gen = Dir.open(@dir_path).to_enum
        end

        def stream?
          return true
        end

        private

        def generate_new_file?(name, mtime)
          return false if ['.', '..'].include?(name)
          return true unless @table.has_key?(name)
          mtime > @table[name]
        end
      end

      # Create a input generator agent by simple method.
      def self.start_by_simple(ts_server, *args)
        start(ts_server, SimpleGeneratorMethod.new(ts_server, ts_server.base_uri, *args))
      end

      # Create a input generator agent by directory method.
      def self.start_by_dir(ts_server, *args)
        start(ts_server, DirGeneratorMethod.new(ts_server, *args))
      end

      # Create a input generator agent by stream method.
      def self.start_by_stream(ts_server, *args)
        start(ts_server, StreamGeneratorMethod.new(ts_server, *args))
      end

      define_state :generating
      define_state :sleeping
      define_state :stop_iteration

      define_state_transition :initialized => :generating
      define_state_transition :generating => :generating
      define_state_transition :stop_iteration => lambda{|agent, res|
        agent.stream? ? :sleeping : :terminated
      }
      define_state_transition :sleeping => :generating

      define_exception_handler StopIteration => :stop_iteration

      attr_reader :counter
      attr_reader :generator

      # Initialize the agent.
      def initialize(ts_server, generator)
        raise ArgumentError unless generator.kind_of?(GeneratorMethod)
        super(ts_server)
        @counter = 0
        @generator = generator
      end

      # Return true if generator of the agent is stream type.
      def stream?
        @generator.stream?
      end

      private

      # State generating generates a data from generator and puts it into tuple
      # space.
      def transit_to_generating
        if input = @generator.generate
          log do |msg|
            msg.add_record(agent_type, "action", "generate_input_data")
            msg.add_record(agent_type, "uuid", uuid)
            msg.add_record(agent_type, "object", input.name)
          end
          write(Tuple[:data].new(DOMAIN, input.name, input.uri, input.time))
          return input
        end
      end

      # State stop_iteration. StopIteration exception is ignored because it
      # means the input generation was completed.
      def transit_to_stop_iteration(e)
        @counter += 1
        if stream?
          @generator.init
        end
      end

      def transit_to_sleeping
        sleep 1
      end
    end

    set_agent InputGenerator
  end
end
