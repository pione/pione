module Pione
  module CommandOption
    module TaskWorkerOwnerOption
      extend OptionInterface

      # --task-worker
      define_option('-t N', '--task-worker=N', 'set task worker number that this process creates') do |n|
        @task_worker = n.to_i
      end
    end
  end
end
