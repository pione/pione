module Pione
  module PNML
    # `AmbiguousNetQueryResult` is an exception that raised when reuslt of net
    # query is ambigous unexpectedly.
    class AmbiguousNetQueryResult < StandardError
      # @param name [String]
      #   net query method name
      # @param query [Object]
      #   the query
      # @param result [Object]
      #   the result
      def initialize(name, query, result)
        @name = name
        @query = query
        @result = result
      end

      def message
        "The result of net query(%s, %s) is ambiguous: %s" % [@name, @query.inspect, @result.inspect]
      end
    end
  end
end
