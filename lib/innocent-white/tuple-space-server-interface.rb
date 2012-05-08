require 'innocent-white/common'

module InnocentWhite
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

    # Log a message.
    def log
      msg = Log.new
      yield msg
      write(Tuple[:log].new(msg))
    end

    # Return the tuple space server.
    def tuple_space_server
      @__tuple_space_server__
    end

    private

    # Set tuple space server which provides operations.
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
