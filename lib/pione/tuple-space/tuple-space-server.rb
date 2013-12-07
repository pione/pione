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
        TupleSpace.from_array(t).tap{|x| x.timestamp = t.timestamp}
      }
      tuple_space_interface :read_all, :result => lambda{|list|
        list.map{|t|
          TupleSpace.from_array(t).tap{|x| x.timestamp = t.timestamp}
        }
      }
      tuple_space_interface :take, :result => lambda{|t|
        TupleSpace.from_array(t).tap{|x| x.timestamp = t.timestamp}
      }
      tuple_space_interface :take_all, :result => lambda{|list|
        list.map {|t| TupleSpace.from_array(t).tap{|x| x.timestamp = t.timestamp}}
      }
      tuple_space_interface :write, :validator => Proc.new {|*args|
        args.first.writable? if args.first.kind_of?(TupleSpace::BasicTuple)
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

      def initialize(data={}, use_proxy=true)
        @__ts__ = Rinda::TupleSpace.new
        @tuple_space = @__ts__
        if use_proxy
          @ts = Rinda::TupleSpaceProxy.new(@__ts__)
        else
          @ts = @__ts__
        end
        def @ts.to_s;"#<Rinda::TupleSpace>" end

        # check task worker resource
        resource = data[:task_worker_resource] || 1
        write(TupleSpace::TaskWorkerResourceTuple.new(number: resource))

        @terminated = false
      end

      # Set base location.
      #
      # @param location [BasicLocation]
      #   base location
      # @return [void]
      def set_base_location(location)
        write(TupleSpace::BaseLocationTuple.new(location.as_directory))
      end

      #def drburi
      #  @remote_object ||= DRb.start_service(nil, self)
      #  @remote_object.__drburi
      #end

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

      # Return common base location of the space.
      #
      # @return [BasicLocation]
      #   base location
      def base_location
        read(TupleSpace::BaseLocationTuple.any).location
      end

      # Return the worker resource size of the server.
      def task_worker_resource
        read(TupleSpace::TaskWorkerResourceTuple.any).number
      end

      # Return the number of tuples matched with specified tuple.
      def count_tuple(tuple)
        read_all(tuple).size
      end

      # Return the current worker size of the server.
      def current_task_worker_size
        read_all(TupleSpace::AgentTuple.new(agent_type: :task_worker)).size
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
      def terminate
        @terminated = true
      end

      # Read a tuple with no waiting time. If there are no matched tuples, return
      # `nil`.
      #
      # @param tuple [BasicTuple]
      #   template tuple for query
      # @return [BasicTuple, nil]
      #   query result
      def read!(tuple)
        begin
          read(tuple, 0)
        rescue Rinda::RequestExpiredError
          nil
        end
      end

      # Take a tuple with no waiting time. If there are no matched tuples, return
      # `nil`.
      #
      # @param tuple [BasicTuple]
      #   template tuple for query
      # @return [BasicTuple, nil]
      #   query result
      def take!(tuple)
        begin
          take(tuple, 0)
        rescue Rinda::RequestExpiredError
          nil
        end
      end

      # Take all tuples with no waiting time. If there are no matched tuples, return
      # empty array.
      #
      # @param tuple [BasicTuple]
      #   template tuple for query
      # @return [Array<BasicTuple>]
      #   query result
      def take_all!(tuple)
        begin
          take_all(tuple, 0)
        rescue Rinda::RequestExpiredError
          []
        end
      end

      def inspect
        "#<Pione::TupleSpace::TupleSpaceServer:%s>" % object_id
      end
    end
  end
end
