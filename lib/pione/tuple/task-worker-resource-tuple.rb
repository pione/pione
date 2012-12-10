module Pione
  module Tuple
    # number of task worker for tuple space server
    class TaskWorkerResourceTuple < BasicTuple
      #   number : resource number of task workers.
      define_format [:task_worker_resource, :number]
    end
  end
end
