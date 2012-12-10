module Pione
  module TupleSpace
    module TupleSpaceServerMethod
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

      # Define tuple space interfaces.
      tuple_space_interface :read, :result => lambda{|t|
        Tuple.from_array(t).tap{|x| x.timestamp = t.timestamp}
      }
      tuple_space_interface :read_all, :result => lambda{|list|
        list.map{|t|
          Tuple.from_array(t).tap{|x| x.timestamp = t.timestamp}
        }
      }
      tuple_space_interface :take, :result => lambda{|t|
        Tuple.from_array(t).tap{|x| x.timestamp = t.timestamp}
      }
      tuple_space_interface :write, :validator => Proc.new {|*args|
        args.first.writable? if args.first.kind_of?(Tuple::BasicTuple)
      }, :result => lambda{|t|
        # don't return raw tuple entry in PIONE
        nil
      }
      tuple_space_interface :notify
    end

    class TupleSpaceServer < PioneObject
      include DRbUndumped
      include TupleSpaceServerMethod

      attr_reader :tuple_space

      def initialize(data={})
        @__ts__ = Rinda::TupleSpace.new
        @tuple_space = @__ts__
        @ts = Rinda::TupleSpaceProxy.new(@__ts__)
        def @ts.to_s;"#<Rinda::TupleSpace>" end

        # check task worker resource
        resource = data[:task_worker_resource] || 1
        write(Tuple[:task_worker_resource].new(number: resource))

        @terminated = false

        # base uri
        if data.has_key?(:base_uri)
          uri = data[:base_uri]
          write(Tuple[:base_uri].new(uri: uri))
        end

        # start agents
        @client_life_checker = Agent::TupleSpaceServerClientLifeChecker.start(self)
      end

      def set_base_uri(uri)
        write(Tuple[:base_uri].new(uri: uri))
      end

      def drburi
        @remote_object ||= DRb.start_service(nil, self)
        @remote_object.__drburi
      end

      def alive?
        not(@terminated)
      end

      # Return pid
      def pid
        Process.pid
      end

      def now
        Time.now
      end

      # Return common base uri of the space.
      def base_uri
        URI.parse(read(Tuple[:base_uri].any).uri)
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

      # Return all tuples of the tuple space.
      def all_tuples(*args)
        @__ts__.all_tuples(*args).compact
      end

      def task_size
        @__ts__.task_size
      end

      def working_size
        @__ts__.working_size
      end

      def finished_size
        @__ts__.finished_size
      end

      def data_size
        @__ts__.data_size
      end

      # Shutdown the server.
      def finalize
        @terminated = true
        write(Tuple[:command].new("terminate"))
        @client_life_checker.terminate
        @client_life_checker.running_thread.join
        sleep 1
      end

      alias :terminate :finalize

      def inspect
        "#<Pione::TupleSpace::TupleSpaceServer:%s>" % object_id
      end
    end
  end
end
