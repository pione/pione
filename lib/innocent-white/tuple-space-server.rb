require 'rinda/tuplespace'
require 'innocent-white/tuple'

module InnocentWhite
  class TupleSpaceServer
    def initialize(data={})
      @ts = Rinda::TupleSpace.new
      if data.has_key?(:task_worker_resource)
        write(Tuple[:task_worker_resource].new(number: data[:task_worker_resource]))
      end
    end

    # Return the worker resource size of the server.
    def task_worker_resource
      read(Tuple[:task_worker_resource].any).to_tuple.number
    end

    # Return the current worker size of the server.
    def current_task_worker_size
      tuple = Tuple[:agent].any
      tuple.agent_type = :task_worker
      read_all(tuple).size
    end

    def task_worker_resource_status
      rs = task_worker_resource_size
      cw = current_task_worker_size
      if rs > cw then
        :less
      elsif rs < cw
        :more
      else
        :just
      end
    end

    # Shutdown the server.
    def shutdown
      write(Tuple[:tuple_server_status].new(status: :stop))
    end

    private

    alias :method_missing_orig :method_missing

    def method_missing(name, *args)
      if @ts.respond_to?(name)
        # convert tuple into plain form
        _args = args.map {|obj| obj.kind_of?(Tuple::TupleData) ? obj.to_a : obj}
        # call
        @ts.__send__(name,*_args)
      else
        method_missing_orig(name, *args)
      end
    end

  end
end
