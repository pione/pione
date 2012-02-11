module InnocentWhite
  module Simulator
    module Agent
      class FakeTaskWorker < ::InnocentWhite::Agent::TaskWorker
        def initialize(spec)
          super
          @t = 0
          @spec = spec
        end

        def countup
          @t += 1
        end

        def step(&b)
          read(Tuple[:step].new(agent_id))
          b.eval
          write(Tuple[:next].new(agent_id))
        end

        def work(task)
          while not task.finished? do
            step do
              task.proceed(spec.calc)
            end
          end
          write(Data::Finished.new(task))
        end
      end

    end
  end
end
