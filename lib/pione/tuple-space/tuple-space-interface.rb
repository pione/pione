module Pione
  module TupleSpace
    module TupleSpaceInterface

      # Define tuple space operation.
      def self.tuple_space_operation(name)
        define_method(name) do |*args, &b|
          @__tuple_space__.__send__(name, *args, &b)
        end
      end

      # define tuple space operations
      tuple_space_operation :read
      tuple_space_operation :read!
      tuple_space_operation :read_all
      tuple_space_operation :take
      tuple_space_operation :take!
      tuple_space_operation :take_all
      tuple_space_operation :take_all!
      tuple_space_operation :write
      tuple_space_operation :count_tuple
      tuple_space_operation :notify

      # Return the tuple space server.
      def tuple_space_server
        @__tuple_space__
      end

      # Put a log tuple with the data as a process record into tuple space. The
      # record's value of transition is "complete" by default and the timestamp
      # set automatically.
      #
      # @param record [Log::ProcessRecord]
      #   process log record
      # @return [void]
      def process_log(record)
        record = record.merge(transition: "complete") unless record.transition
        write(TupleSpace::ProcessLogTuple.new(record))
      end

      # Do the action with loggging.
      #
      # @param record [Log::ProcessRecord]
      #   process log record
      # @yield
      #   the action
      # @return [void]
      def with_process_log(record)
        process_log(record.merge(transition: "start"))
        result = yield
        process_log(record.merge(transition: "complete"))
        return result
      rescue DRb::DRbConnError
        yield
      end

      # Send a processing error.
      #
      # @param msg [String]
      #   error message
      # @return [void]
      def processing_error(msg)
        write(TupleSpace::CommandTuple.new(name: "terminate", args: {message: msg}))
      end

      # Set tuple space server which provides operations.
      # @return [void]
      def set_tuple_space(server)
        @__tuple_space__ = server

        # override #to_s as it's uri because dead remote objects cause exceptions
        # when you try to watch the object
        if server.methods.include?(:__drburi)
          def @__tuple_space__.to_s
            __drburi
          end
        end
      end
    end
  end
end
