require 'innocent-white/common'
require 'innocent-white/agent'
require 'innocent-white/uri'
require 'innocent-white/resource'

module InnocentWhite
  module Agent
    class InputGenerator < InnocentWhite::Agent::Base
      set_agent_type :input_generator

      InputData = Struct.new(:name, :uri)

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

      # -- class --

      def self.start_by_simple(ts_server, *args)
        start(ts_server, SimpleGeneratorMethod.new(ts_server.base_uri, *args))
      end

      def self.start_by_dir(ts_server, *args)
        start(ts_server, DirGeneratorMethod.new(*args))
      end

      # -- instance --

      define_state :generating

      define_state_transition :initialized => :generating
      define_state_transition :generating => :generating

      attr_accessor :domain

      # State initialized.
      def initialize(ts_server, generator)
        raise ArgumentError unless generator.kind_of?(GeneratorMethod)
        super(ts_server)
        @generator = generator
        @domain = "/input"
      end

      # State generating.
      def transit_to_generating
        input = @generator.generate
        write(Tuple[:data].new(domain: @domain, name: input.name, uri: input.uri))
        log(:debug, "generated #{input.name}")
      end

      # State error. StopIteration exception is ignored because it means the
      # input generation was completed.
      def transit_to_error(e)
        notify_exception(e) unless e.kind_of?(StopIteration)
        terminate
      end
    end

    set_agent InputGenerator

  end
end
