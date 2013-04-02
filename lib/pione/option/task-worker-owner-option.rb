module Pione
  module Option
    # TaskWorkerOwnerOption provides options for commands that make task
    # workers. Options are:
    #
    # - task-worker
    # - features
    module TaskWorkerOwnerOption
      extend OptionInterface

      default :task_worker, [Util.core_number - 1, 1].max

      # --task-worker
      option('-t N', '--task-worker=N', 'set task worker number that this process creates') do |data, n|
        data[:task_worker] = n.to_i
      end

      # --features
      option('--features=FEATURES', 'set features') do |data, features|
        data[:features] = features
      end
    end
  end
end
