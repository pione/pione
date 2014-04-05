module Pione
  module TaskWorkerBroker
    # `BasicProvider` is an abstract class for task worker providers.
    class BasicProvider
      # @param model [Model::TaskWorkerBrokerModel]
      #   model of task worker broker
      def initialize(model)
        @model = model
      end

      # Execute task worker provisioning. If this method returned true, broker
      # executes retry provision transition with no span. If false, broker
      # sleeps a little.
      def provide
        raise NotImplementedError
      end
    end
  end
end

