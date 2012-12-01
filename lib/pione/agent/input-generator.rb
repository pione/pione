module Pione
  module Agent
    class InputGenerator < TupleSpaceClient
      set_agent_type :input_generator

      InputData = Struct.new(:name, :uri, :time)
      DOMAIN = "input"

      # Base class for generator methods.
      class GeneratorMethod
        def initialize(ts_server)
          @tuple_space_server = ts_server
        end

        def now
          @tuple_space_server.now
        end

        # Generates an input.
        def generate
          raise RuntimeError
        end

        # Return true if the generator is stream.
        # @return [Boolean]
        #   true if the generator is stream mode
        def stream?
          return false
        end
      end

      # Directory based generator.
      class DirGeneratorMethod < GeneratorMethod
        # Create a generator.
        # @param [TupleSpaceServer] ts_server
        #   tuple space server
        # @param [URI] dir_path
        #   directory URI for loading target
        def initialize(ts_server, dir_path)
          raise TypeError.new(dir_path) unless dir_path.kind_of?(URI) or dir_path.nil?
          super(ts_server)
          @dir_path = dir_path
          if dir_path
            @gen = Resource[@dir_path].entries.to_enum
          else
            @gen = [].each
          end
        end

        def generate
          item = @gen.next
          InputData.new(item.basename, item.uri, item.mtime)
        end
      end

      # StreamGeneratorMethod handles stream inputs.
      class StreamGeneratorMethod < GeneratorMethod
        def initialize(ts_server, dir_path)
          raise TypeError.new(dir_path) unless dir_path.kind_of?(URI) or dir_path.nil?
          super(ts_server)
          @dir_path = dir_path
          @table = Hash.new
          init
        end

        def generate
          item = @gen.next
          if generate_new_file?(item.basename, item.mtime)
            @table[item.basename] = item.mtime
            return InputData.new(item.basename, item.uri, item.mtime)
          else
            return nil
          end
        end

        # Initializes the generator. This method is called when root rule is
        # requested in stream mode.
        # @retrun [void]
        def init
          if @dir_path
            @gen = Resource[@dir_path].entries.to_enum
          else
            @gen = [].each
          end
        end

        # @api private
        def stream?
          return true
        end

        private

        # Return true if it is new file.
        # return [Boolean]
        #   return true if the file is new.
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

      define_state_transition :initialized => :reading_base_uri
      define_state_transition :reading_base_uri => :generating
      define_state_transition :generating => :generating
      define_state_transition :stop_iteration => lambda{|agent, res|
        agent.stream? ? :sleeping : :terminated
      }
      define_state_transition :sleeping => :generating

      define_exception_handler StopIteration => :stop_iteration

      attr_reader :generator

      # Initialize the agent.
      def initialize(ts_server, generator)
        raise ArgumentError unless generator.kind_of?(GeneratorMethod)
        super(ts_server)
        @generator = generator
        @inputs = []
      end

      # Return true if generator of the agent is stream type.
      def stream?
        @generator.stream?
      end

      private

      def transit_to_reading_base_uri
        @base_uri = read(Tuple[:base_uri].any).uri
      end

      # State generating generates a data from generator and puts it into tuple
      # space.
      def transit_to_generating
        if input = @generator.generate
          @inputs << input
          # log
          log do |msg|
            msg.add_record(agent_type, "action", "generate_input_data")
            msg.add_record(agent_type, "uuid", uuid)
            msg.add_record(agent_type, "object", input.name)
          end
          # upload the file
          input_uri = @base_uri + File.join("input", input.name)
          Resource[input_uri].create(Resource[input.uri].read)
          # make the tuple
          write(Tuple[:data].new(DOMAIN, input.name, input_uri, input.time))
        end
      end

      # State stop_iteration. StopIteration exception is ignored because it
      # means the input generation was completed.
      def transit_to_stop_iteration(e)
        # start root rule
        if not(@inputs.empty?) or not(stream?)
          write(Tuple[:command].new("start-root-rule"))
        end
        terminate unless stream?
      end

      def transit_to_sleeping
        sleep Global.input_generator_stream_check_timespan

        # init stream generator
        @generator.init
        @inputs = []
      end
    end

    set_agent InputGenerator
  end
end
