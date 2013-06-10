module Pione
  module Option
    # TaskWorkerOwnerOption provides options for commands that make task
    # workers.
    module TaskWorkerOwnerOption
      extend OptionInterface

      define(:task_worker) do |item|
        item.short = '-t N'
        item.long = '--task-worker=N'
        item.desc = 'set task worker number that this process creates'
        item.default = Agent::TaskWorker.default_number
        item.value = proc {|n| n.to_i}
      end

      define(:features) do |item|
        item.long = '--features=FEATURES'
        item.desc = 'set features'
        item.value = proc {|features| features}
      end
    end
  end
end
