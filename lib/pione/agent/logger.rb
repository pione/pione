module Pione
  module Agent
    # Logger is an agent for logging process events like agent activity or rule
    # process.
    class Logger < TupleSpaceClient
      set_agent_type :logger

      # @return [BasicLocation]
      attr_reader :log_location

      # @return [Pathname]
      attr_reader :output_location

      # Create a logger agent.
      #
      # @param tuple_space_server [TupleSpaceServer]
      #   tuple space server
      # @param location [BasicLocation]
      #   the path to store log records
      def initialize(tuple_space_server, base_location)
        super(tuple_space_server)
        @log_id = Time.now.iso8601(3)
        @log_location = base_location + "pione-process.log"
        @output_location = get_output_location
      end

      define_state :initialized
      define_state :record
      define_state :terminated

      define_state_transition :initialized => :record
      define_state_transition :record => :record

      # Sleeps till the logger clears logs.
      #
      # @param [Float]
      #   timespan for clearing logs
      # @return [void]
      def wait_to_clear_logs(timespan=0.1)
        while count_tuple(Tuple[:process_log].any) > 0
          sleep timespan
        end
      end

      # Record process_log tuples.
      def transit_to_record
        write_records(take_all(Tuple[:process_log].any))
      end

      # Copy from output to log when log and output are different.
      def transit_to_terminated
        write_records(take_all!(Tuple[:process_log].any))
        if @log_location != @output_location
          @output_location.copy(@log_location)
        end
        super
      end

      private

      # Write records with sorting.
      def write_records(tuples)
        tuples.sort{|a,b| a.timestamp <=> b.timestamp}.each do |tuple|
          @output_location.append tuple.message.format(@log_id) + "\n"
        end
      end

      # Get the output location. If the log location is not suportted append
      # writing, output location is in local filesystem.
      def get_output_location
        if @log_location.real_appendable?
          @log_location
        else
          Location[Pione.temporary_path(@location.basename)]
        end
      end
    end

    set_agent Logger
  end
end
