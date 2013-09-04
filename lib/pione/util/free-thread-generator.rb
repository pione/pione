module Pione
  module Util
    # FreeThreadGenerator provides the function that creates new threads under
    # main thread group. This is useful for escaping threadgroup encloser.
    module FreeThreadGenerator
      @queue = Queue.new                        # task queue
      @method_lock = Mutex.new                  # method lock
      @mutex = Mutex.new                        # generator lock
      @cv_response = ConditionVariable.new      # response cv
      @cv_bye = ConditionVariable.new           # bye client cv
      @thread = Thread.new {create_free_thread} # a thread under default thread group
      @__generated__ = nil                      # generated thread(temporary variable)

      # Generate a thread with the block under default thread group.
      def self.generate(&b)
        @method_lock.synchronize do
          @mutex.synchronize do
            @queue.push(b)
            @cv_response.wait(@mutex)
            thread = @__generated__
            @__generated__ = nil
            @cv_bye.signal
            return thread
          end
        end
      end

      private

      # Start to run a loop for creating threadgroup free thread.
      def self.create_free_thread
        while true
          b = @queue.pop
          @mutex.synchronize do
            @__generated__ = Thread.new(&b)
            @cv_response.signal
            @cv_bye.wait(@mutex)
          end
        end
      end
    end
  end
end
