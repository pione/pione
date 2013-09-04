module Pione
  module Agent
    class InputGenerator < TupleSpaceClient
      set_agent_type :input_generator, self
      DOMAIN = "root"

      @generator_method = Hash.new

      class << self
        attr_reader :generator_method
      end

      #
      # agent activity
      #

      define_transition :generate
      define_transition :sleep
      define_transition :stop_iteration

      chain :init => :generate
      chain :generate => :generate
      chain :stop_iteration => lambda {|agent|
        agent.generator.stream ? :sleep : :terminate
      }
      chain :sleep => :init

      define_exception_handler StopIteration => :stop_iteration

      #
      # instance methods
      #

      attr_reader :generator
      forward :@generator, :stream?

      # Initialize the agent.
      def initialize(space, generator_name, input_location, stream)
        super(space)
        @base_location = base_location

        # generator method
        if generator_method = InputGenerator.generator_method[generator_name]
          @generator = generator_method.new(space, input_location, stream)
        else
          raise UnknownInputGeneratorMethod.new(generator_name)
        end
      end

      #
      # transitions
      #

      def transit_to_init
        @generator.init
        @inputs = []
      end

      # Generate a input data tuple and put it into tuple space.
      def transit_to_generate
        if input = @generator.generate
          # put into history
          @inputs << input

          # build original location
          orig_location = input.location

          # build input location
          input_location = @base_location + "input" + input.name

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
          write(input.set(location: input_location))
        end
      end

      # State stop_iteration. StopIteration exception is ignored because it
      # means the input generation was completed.
      def transit_to_stop_iteration(e)
        if not(@inputs.empty?) or not(@generator.stream?)
          write(Tuple[:command].new("start-root-rule", nil))
        end
      end

      def transit_to_sleep
        sleep Global.input_generator_stream_check_timespan
      end
    end

    # InputGeneratorMethod is an interface class for generator methods.
    class InputGeneratorMethod
      def self.method_name(name)
        InputGenerator.generator_method[name] = self
      end

      attr_reader :input_location
      attr_reader :stream
      alias :stream? :stream

      def initialize(space, input_location, stream)
        @__space__ = space
        @input_location = input_location
        @stream = stream
      end

      # Return current time. The time is based on tuple space.
      def now
        @__space__.now
      end

      # Initialize the generator method.
      def init
        raise NotImplementedError
      end

      # Generate an input tuple.
      def generate
        raise NotImplementedError
      end
    end

    # DirGeneratorMethod is a directory based generator.
    class DirInputGeneratorMethod < InputGeneratorMethod
      method_name :dir

      def initialize(space, input_location, stream)
        super
        @table ||= Hash.new
      end

      def init
        # save entries as Enumerator
        if input_location
          # files in the directory
          @enum = input_location.file_entries.to_enum
        else
          # no files
          @enum = [].to_enum
        end
      end

      def generate
        location = @enum.next
        if new_file?(location.basename, location.mtime)
          @table[location.basename] = location.mtime
          return Tuple[:data].new(InputGenerator::DOMAIN, location.basename, location, location.mtime)
        end
      end

      private

      # Return true if it is a new file.
      def new_file?(name, mtime)
        # unknown file
        return true unless @table.has_key?(name)
        # updated file
        return mtime > @table[name]
      end
    end
  end
end
