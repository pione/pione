module Pione
  module TupleSpace
    class Manager
      def initialize(cmd)
        @cmd = cmd
        @table = Hash.new
        @lock = Mutex.new
      end

      def create
        @lock.synchronize do
          spawner = Command::PioneTupleSpaceProvider.spawn(@cmd)
          tuple_space = spawner.child_front.tuple_space
          id = tuple_space.uuid

          @table[id] = tuple_space

          spawner.when_terminated do
            @lock.synchronize { @table[id] = nil }
          end

          return spawner.child_front.uri.to_s
        end
      end

      def close_tuple_space(tuple_space_id)
        @lock.synchronize do
          @table[tuple_space_id].terminate
          @table[tuple_space_id] = nil
        end
      end
    end
  end
end
