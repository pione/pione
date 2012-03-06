require 'innocent-white/common'
require 'innocent-white/tuple-space-provider'

module InnocentWhite
  class TupleSpaceServer < InnocentWhiteObject
    include DRbUndumped

    # -- class --

    def self.tuple_space_interface(name, opt={})
      define_method(name) do |*args, &b|
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
        result = @ts.__send__(name, *_args, &b)
        # convert the result to tuple object
        if converter = opt[:result]
          converter.call(result)
        else
          result
        end
      end
    end

    # -- instance --

    def initialize(data={})
      @__ts__ = Rinda::TupleSpace.new
      @ts = Rinda::TupleSpaceProxy.new(@__ts__)
      def @ts.to_s;"#<Rinda::TupleSpace>" end

      # check task worker resource
      resource = data[:task_worker_resource] || 1
      write(Tuple[:task_worker_resource].new(number: resource))

      @terminated = false
      @provider_options = {} ## FIXME

      # base uri
      if data.has_key?(:base_uri)
        uri = data[:base_uri]
        write(Tuple[:base_uri].new(uri: uri))
      end

      # keep provider
      keep_provider

      # watch bye message
      check_agent_life
    end

    def alive?
      not(@terminated)
    end

    # Return pid
    def pid
      Process.pid
    end

    # Return common base uri of the space.
    def base_uri
      URI(read(Tuple[:base_uri].any).uri)
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
    def finalize
      @terminated = false
    end

    alias :terminate :finalize

    # Define tuple space interfaces.
    tuple_space_interface :read, :result => lambda{|t| Tuple.from_array(t)}
    tuple_space_interface :read_all, :result => lambda{|list| list.map{|t| Tuple.from_array(t)}}
    tuple_space_interface :take, :result => lambda{|t| Tuple.from_array(t)}
    tuple_space_interface :write, :validator => Proc.new {|*args|
      args.first.writable? if args.first.kind_of?(Tuple::TupleObject)
    }
    tuple_space_interface :notify

    private

    def keep_provider
      @thread_keep_provider = Thread.new do
        while true do
          begin
            provider.add(remote_object_uri)
            sleep 1
          rescue
            # do nothing
          end
        end
      end
    end

    def provider
      TupleSpaceProvider.instance(@provider_options)
    end

    def check_agent_life
      @thread_check_agent_life = Thread.new do
        while true do
          agent = take(Tuple[:bye].any)
          take(Tuple[:agent].new(uuid: agent.uuid))
        end
      end
    end
  end

  module TupleSpaceServerInterface

    # Define tuple space operation.
    def self.tuple_space_operation(name)
      define_method(name) do |*args, &b|
        @__tuple_space_server__.__send__(name, *args, &b)
      end
    end

    # define perations
    tuple_space_operation :read
    tuple_space_operation :read_all
    tuple_space_operation :take
    tuple_space_operation :write
    tuple_space_operation :count_tuple
    tuple_space_operation :notify

    # Log a message.
    def log(level, msg)
      write(Tuple[:log].new(level, msg))
    end

    private

    # Return the tuple space server.
    def get_tuple_space_server
      @__tuple_space_server__
    end

    # Set tuple space server which provides operations.
    def set_tuple_space_server(server)
      @__tuple_space_server__ = server

      # override #to_s as it's uri because dead remote objects cause exceptions
      # when you try to watch the object
      def @__tuple_space_server__.to_s
        __drburi
      end
    end
  end
end
