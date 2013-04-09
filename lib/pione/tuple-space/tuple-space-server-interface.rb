module Pione
  module TupleSpaceServerInterface

    # Define tuple space operation.
    def self.tuple_space_operation(name)
      define_method(name) do |*args, &b|
        @__tuple_space_server__.__send__(name, *args, &b)
      end
    end

    # define tuple space operations
    tuple_space_operation :read
    tuple_space_operation :read_all
    tuple_space_operation :take
    tuple_space_operation :write
    tuple_space_operation :count_tuple
    tuple_space_operation :notify

    # Return the tuple space server.
    def tuple_space_server
      @__tuple_space_server__
    end

    private

    # Read a tuple with no waiting time. If there are no matched tuples, return
    # +nil+.
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
    # +nil+.
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

    # Write log tuple of the component activity with the data.
    #
    # @param component [String]
    #   component name
    # @param data [Hash{Symbol => Object}]
    #   data
    # @return [void]
    def log(component, data)
      write(Tuple[:log].new(Log::ProcessRecord.new(component, nil, ({:transition => "complete"}.merge(data)))))
    end

    # Do the action with loggging the message.
    #
    # @param component [String]
    #   component name
    # @param data [Hash]
    #   log content
    # @return [void]
    def with_log(component, data)
      write(Tuple[:log].new(Log::ProcessRecord.new(component, nil, data.merge({:transition => "start"}))))
      result = yield
      write(Tuple[:log].new(Log::ProcessRecord.new(component, nil, data.merge({:transition => "complete"}))))
      return result
    end

    # Send a processing error.
    #
    # @param msg [String]
    #   error message
    # @return [void]
    def processing_error(msg)
      write(Tuple[:command].new(name: "terminate", args: {message: msg}))
    end

    # Set tuple space server which provides operations.
    # @return [void]
    def set_tuple_space_server(server)
      @__tuple_space_server__ = server

      # override #to_s as it's uri because dead remote objects cause exceptions
      # when you try to watch the object
      if server.methods.include?(:__drburi)
        def @__tuple_space_server__.to_s
          __drburi
        end
      end
    end
  end
end
