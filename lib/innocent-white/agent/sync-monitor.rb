require 'innocent-white/common'

module InnocentWhite
  module Agent
    class SyncMonitor < Base
      set_agent_type :sync_monitor

      define_state :initialized
      define_state :sync_target_waiting
      define_state :sync_checking
      define_state :error
      define_state :terminated

      define_state_transition :initialized => :sync_target_waiting
      define_state_transition :sync_target_waiting => :sync_checking
      define_state_transition :sync_checking => :sync_target_waiting
      define_exception_handler :error

      attr_reader :queue

      def initialize(ts_server, handler)
        super(ts_server)
        @handler = handler
        @domain = handler.domain
        @queue = []
      end

      private

      # State initialized.
      def transit_to_initialized
        # do nothing
      end

      # State sync_target_waiting
      def transit_to_sync_target_waiting
        @queue.push(take(Tuple[:sync_target].new(dest: @domain)))
      end

      # State sync_checking
      def transit_to_sync_checking
        sync if check_sync_condition
      end

      def transit_to_error(e)
        notify_exception(e)
        terminate
      end

      def transit_to_terminated
        # do nothing
      end

      # Check sync conditions:
      # 1. monitor target flow rule is waiting for finished tuple.
      # 2. task tuple is empty on the domain.
      def check_sync_condition
        if @handler.finished_waiting?
          tasks = read_all(Tuple[:task].new(domain: @domain))
          workings = read_all(Tuple[:working].new(domain: @domain))
          return (tasks.empty? and workings.empty?)
        else
          return false
        end
      end

      # Do synchronization.
      def sync
        @queue.size.times do
          target = @queue.pop
          new_data = read(Tuple[:data].new(domain: target.src, name: target.name))
          new_data.domain = target.dest
          write(new_data)
        end
        write(Tuple[:finished].new(domain: @domain, status: true))
      end
    end

    set_agent SyncMonitor
  end
end
