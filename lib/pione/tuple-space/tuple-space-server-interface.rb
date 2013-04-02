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

    # Reads a tuple without waiting.
    # @return [Tuple]
    def read0(tuple)
      read(tuple, 0)
    end

    # Takes a tuple without wainting.
    # @return [Tuple]
    def take0(tuple)
      take(tuple, 0)
    end

    # Do the action with loggging the message.
    #
    # @param component [String]
    #   component name
    # @param data [Hash]
    #   log content
    # @return [void]
    def with_log(component, data)
      write(Tuple[:log].new(Log.new(component, data.merge({:transition => "start"}))))
      result = yield
      write(Tuple[:log].new(Log.new(component, data.merge({:transition => "complete"}))))
      return result
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
