require 'rinda/tuplespace'
require 'innocent-white/innocent-white-object'
require 'innocent-white/tuple'

module InnocentWhite
  class TupleSpaceServer < InnocentWhiteObject

    # -- class --

    def self.tuple_space_interface(name, opt={})
      define_method(name) do |*args|
        # convert tuple space form
        _args = args.map do |obj|
          tuple_form = obj.respond_to?(:to_tuple_space_form)
          tuple_form ? obj.to_tuple_space_form : obj
        end
        # check arguments
        if opt.has_key?(:validator)
          opt[:validator].call(args)
        end
        # send a message to the tuple space
        result = @ts.__send__(name, *_args)
        # convert the result to tuple object
        if converter = opt[:result]
          converter.call(result)
        else
          result
        end
      end
    end

    # -- object --

    def initialize(data={})
      @ts = Rinda::TupleSpace.new
      def @ts.to_s;"#<Rinda::TupleSpace>" end

      # check task worker resource
      if data.has_key?(:task_worker_resource)
        resource = data[:task_worker_resource]
        write(Tuple[:task_worker_resource].new(number: resource))
      else
        raise ArgumentError
      end

      check_agent_life
    end

    # Return the worker resource size of the server.
    def task_worker_resource
      read(Tuple[:task_worker_resource].any).number
    end

    # Return the number of tuples matched with specified tuple.
    def count_tuple(tuple)
      read_all(tuple).size
    end

    # Return the current worker size of the server.
    def current_task_worker_size
      tuple = Tuple[:agent].any
      tuple.agent_type = :task_worker
      read_all(tuple).size
    end

    # Shutdown the server.
    def shutdown
      write(Tuple[:tuple_server_status].new(status: :stop))
    end

    def report
      { task_worker_resource: task_worker_resource,
        current_task_worker_size: current_task_worker_size,
        tuples: all_tuples }
    end

    # Return all tuples of the tuple space.
    def all_tuples
      tuples = []
      bag = @ts.instance_variable_get("@bag")
      bag.instance_variable_get("@hash").values.each do |bin|
        tuples += bin.instance_variable_get("@bin")
      end
      _tuples = tuples.map{|t| t.value}
      return _tuples
    end

    tuple_space_interface :read, :result => lambda{|t| Tuple.from_array(t)}
    tuple_space_interface :read_all
    tuple_space_interface :take, :result => lambda{|t| Tuple.from_array(t)}
    tuple_space_interface :write, :validator => Proc.new {|*args|
      args.first.writable? if args.first.kind_of?(Tuple::TupleObject)
    }

    private

    def check_agent_life
      @thread_check_agent_life = Thread.new do
        loop do
          agent = take(Tuple[:bye].any)
          take(Tuple[:agent].new(agent_type: agent.agent_type, uuid: agent.uuid))
        end
      end
    end
  end

  module TupleSpaceServerInterface
    def self.tuple_space_operation(name)
      define_method(name) do |*args|
        @__tuple_space_server__.__send__(name, *args)
      end
    end

    def set_tuple_space_server(server)
      @__tuple_space_server__ = server
    end

    tuple_space_operation :read
    tuple_space_operation :read_all
    tuple_space_operation :take
    tuple_space_operation :write

    # Log a message.
    def log(level, msg)
      write(Tuple[:log].new(level, msg))
    end

  end
end
