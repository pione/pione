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

        # Generate an input.
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

      # DirGeneratorMethod is a directory based generator.
      class DirGeneratorMethod < GeneratorMethod
        # Create a generator.
        #
        # @param tuple_space_server [TupleSpaceServer]
        #   tuple space server
        # @param dir [BasicLocation]
        #   input directory location
        def initialize(tuple_space_server, dir)
          raise Argument.new(dir) unless dir.kind_of?(Location::BasicLocation) or dir.nil?
          super(tuple_space_server)
          @gen = dir ? dir.file_entries.to_enum : [].each
        end

        def generate
          item = @gen.next
          InputData.new(item.basename, item.uri, item.mtime)
        end
      end

      # StreamGeneratorMethod handles stream inputs.
      class StreamGeneratorMethod < GeneratorMethod
        def initialize(ts_server, dir)
          raise TypeError.new(dir) unless dir.kind_of?(Location) or dir.nil?
          super(ts_server)
          @dir = dir
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

        # Initialize the generator. This method is called when root rule is
        # requested in stream mode.
        #
        # @return [void]
        def init
          @gen = dir ? @dir.entries.to_enum : [].each
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

      def transit_to_initialized
        @base_location = base_location
      end

      # State generating generates a data from generator and puts it into tuple
      # space.
      def transit_to_generating
        if input = @generator.generate
          # put into history
          @inputs << input

          # build original location
          orig_location = Location[input.uri]

          # build input location
          input_location = @base_location + File.join("input", input.name)

          # make process log record
          record = Log::PutDataProcessRecord.new.tap do |record|
            record.agent_type = agent_type
            record.agent_uuid = uuid
            record.location = input_location
            record.size = orig_location.size
          end

          # upload the file
          with_process_log(record) do
            orig_location.copy(input_location)
          end

          # put data tuple into tuple space
          write(Tuple[:data].new(DOMAIN, input.name, input_location, input.time))
        end
      end

      # State stop_iteration. StopIteration exception is ignored because it
      # means the input generation was completed.
      def transit_to_stop_iteration(e)
        # start root rule
        if not(@inputs.empty?) or not(stream?)
          write(Tuple[:command].new("start-root-rule", nil))
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
