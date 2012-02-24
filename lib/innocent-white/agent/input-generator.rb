require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class InputGenerator < InnocentWhite::Agent::Base
      set_agent_type :input_generator

      InputData = Struct.new(:name, :value, :path)

      # Base class for generator methods.
      class GeneratorMethod
        def generate
          raise RuntimeError
        end
      end

      # Simple generator based on range and extension.
      class SimpleGeneratorMethod < GeneratorMethod
        def initialize(name, name_range, value_range)
          @name = name
          @name_range = name_range.to_enum
          @value_range = value_range.to_enum
        end

        def generate
          name = Rule::DataNameExp.new(@name).generate(@name_range.next)
          value = @value_range.next
          InputData.new(name, value, nil)
        end
      end

      # Directory based generator.
      class DirGeneratorMethod < GeneratorMethod
        def initialize(dir_path, path_mode=true)
          @dir_path = dir_path
          @gen = Dir.open(dir_path).to_enum
          @path_mode = path_mode
        end

        def generate
          name = @gen.next
          path = File.join(@dir_path, name)
          if ['.', '..'].include?(name)
            generate
          else
            if @path_mode
              InputData.new(name, nil, path)
            else
              value = File.read(path)
              InputData.new(name, value, nil)
            end
          end
        end
      end

      # -- class --

      def self.new_by_simple(ts_server, *args)
        new(ts_server, SimpleGeneratorMethod.new(*args))
      end

      def self.new_by_dir(ts_server, *args)
        new(ts_server, DirGeneratorMethod.new(*args))
      end

      # -- instance --

      define_state :initialized
      define_state :generating
      define_state :terminated

      define_state_transition :initialized => :generating
      define_state_transition :generating => :generating
      define_exception_handler :error

      # State initialized.
      def initialize(ts_server, generator)
        raise ArgumentError unless generator.kind_of?(GeneratorMethod)
        super(ts_server)
        @generator = generator
      end

      def transit_to_initialized
        # do nothing
      end

      # State generating.
      def transit_to_generating
        input = @generator.generate
        tuple = Tuple[:data].new(name: input.name, domain: "/")
        if input.value
          tuple.value = input.value
        else
          tuple.path = input.path
        end
        write(tuple)
        log(:debug, "generated #{input.name}")
      end

      # State error.
      # StopIteration exception means the input generation was completed.
      def transit_to_error(e)
        unless e.kind_of?(StopIteration)
          Util.ignore_exception { write(Tuple[:exception].new(e)) }
        end
        terminate
      end

      # State terminated.
      def transit_to_terminated
        Util.ignore_exception { bye }
      end
    end

    set_agent InputGenerator

  end
end
