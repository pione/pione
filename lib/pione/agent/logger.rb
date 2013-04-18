module Pione
  module Agent
    # Logger is an agent for logging processings in tuple space.
    class Logger < TupleSpaceClient
      set_agent_type :logger

      # @return [BasicLocation]
      attr_reader :location

      # @return [Pathname]
      attr_reader :out

      # @return [Array<Log::ProcessRecord>]
      attr_reader :records

      # Create a logger agent.
      #
      # @param tuple_space_server [TupleSpaceServer]
      #   tuple space server
      # @param location [BasicLocation]
      #   the path to store log records
      def initialize(tuple_space_server, location)
        super(tuple_space_server)
        @location = location
        @temporary = Location[Pione.temporary_path(@location.basename)]
        @out = @temporary.path.open("w+")
        @records = []
      end

      define_state :initialized
      define_state :take
      define_state :store
      define_state :terminated

      define_state_transition :initialized => :take
      define_state_transition :take => :store
      define_state_transition :store => :take

      define_exception_handler Exception => :terminated

      # Sleeps till the logger clears logs.
      #
      # @param [Float]
      #   timespan for clearing logs
      # @return [void]
      def wait_to_clear_logs(timespan=0.1)
        while count_tuple(Tuple[:log].any) > 0 || @records.size > 0
          sleep timespan
        end
      end

      def store_records
        unless @records.empty?
          @records.sort{|a,b| a.timestamp <=> b.timestamp}.each do |record|
            @out.puts record.format
          end
          @out.flush
          @out.fsync
          @records = []
        end
      end

      private

      # Transits to the state +take+.
      def transit_to_take
        timeout(2) do
          loop do
            if @current_tuple = take(Tuple[:log].any)
              @records << @current_tuple.message
              @current_tuple = nil
            end
          end
        end
      rescue TimeoutError
        if @current_tuple
          @records << @current_tuple.message
          @current_tuple = nil
        end
      end

      # Transits to the state +store+.
      def transit_to_store
        store_records
      end

      # State terminated.
      def transit_to_terminated
        store_records
        Util.ignore_exception {@out.close}
        @temporary.copy(@location)
        super
      end
    end

    set_agent Logger
  end
end
