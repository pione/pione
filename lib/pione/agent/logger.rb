module Pione
  module Agent
    # Logger is an agent for logging process events like agent activity or rule
    # process.
    class Logger < TupleSpaceClient
      set_agent_type :logger, self

      attr_reader :log_location       # location of log file
      attr_reader :temporary_location # temporary location

      # Create a logger agent.
      def initialize(tuple_space, location)
        super(tuple_space)
        @log_id = Time.now.iso8601(3)
        @log_location = location.directory? ? location + "pione-process.log" : location
        @temporary_location = get_temporary_location
      end

      #
      # agent activities
      #

      define_transition :record

      chain :init => :record
      chain :record => :record

      #
      # transitions
      #

      # Record process_log tuples.
      def transit_to_record
        begin
          write_records(take_all(TupleSpace::ProcessLogTuple.any))
        rescue => e
          # logger is terminated at last in termination processes, so tuple space may be closed
          Log::SystemLog.warn("logger agent failed to take process logs: %s" % e.message)
          terminate
        end
      end

      # Copy from temporary location to log location.
      def transit_to_terminate
        begin
          write_records(take_all!(TupleSpace::ProcessLogTuple.any))
        rescue => e
          # logger is terminated at last in termination processes, so tuple space may be closed
          Log::SystemLog.warn("logger agent failed to take process logs.", self, e)
        end
        if @log_location != @temporary_location
          @temporary_location.copy(@log_location)
        end
        super
      end

      private

      #
      # helper methods
      #

      # Write records with sorting.
      def write_records(tuples)
        tuples.sort{|a,b| a.timestamp <=> b.timestamp}.each do |tuple|
          @temporary_location.append tuple.message.format(@log_id) + "\n"
        end
      end

      # Get the temporary location. If the log location doesn't suport append
      # writing, output location is in local filesystem.
      def get_temporary_location
        if @log_location.real_appendable?
          @log_location
        else
          Location[Temppath.mkdir + @log_location.basename]
        end
      end
    end
  end
end
