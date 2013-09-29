module Pione
  module Agent
    # Messenger is an agent for receiveing message logs.
    class Messenger < TupleSpaceClient
      set_agent_type :messenger, self

      #
      # agent activities
      #

      define_transition :print

      chain :init => :print
      chain :print => :print

      #
      # transitions
      #

      # Transits to the state +print+.
      def transit_to_print
        tuples = take_all(TupleSpace::MessageTuple.any)
        tuples.sort{|a,b| a.timestamp <=> b.timestamp}.each do |tuple|
          msgs = tuple.contents
          msgs = [msgs] if tuple.contents.kind_of?(String)
          msgs.each do |msg|
            puts "%s%s %s" % ["  "*tuple.level, ("%5s" % tuple.head).color(tuple.color), msg]
          end
        end
      end
    end
  end
end
