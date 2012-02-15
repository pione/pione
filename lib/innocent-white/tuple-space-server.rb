require 'rinda/tuplespace'
require 'innocent-white/innocent-white-object'
require 'innocent-white/tuple'

module InnocentWhite
  class TupleSpaceServer < InnocentWhiteObject
    def initialize(data={})
      @ts = Rinda::TupleSpace.new
      def @ts.to_s;"#<Rinda::TupleSpace>" end
      if data.has_key?(:task_worker_resource)
        write(Tuple[:task_worker_resource].new(number: data[:task_worker_resource]))
      else
        raise ArgumentError
      end
    end

    # Return the worker resource size of the server.
    def task_worker_resource
      read(Tuple[:task_worker_resource].any).to_tuple.number
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

    def report
      txt = <<-REPORT
task_worker_resource: #{task_worker_resource}
current_task_worker_size: #{current_task_worker_size}
tuples:
REPORT
    end

    private

    alias :method_missing_orig :method_missing

    # Send a message to the real tuple space.
    def method_missing(name, *args)
      if @ts.respond_to?(name)
        # convert tuple space form
        _args = args.map do |obj|
          if obj.respond_to?(:to_tuple_space_form)
            obj.to_tuple_space_form
          else
            obj
          end
        end

        # call
        @ts.__send__(name,*_args)
      else
        method_missing_orig(name, *args)
      end
    end

  end
end
