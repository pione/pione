require 'innocent-white/tuple'
require 'innocent-white/simulator/input-generator'

include InnocentWhite
Thread.abort_on_exception = true

describe "Simulator" do
  describe "InputGenerator" do
    before do
      @ts_server = TupleSpaceServer.new(task_worker_resource: 4)
    end

    it "should provide files" do
      generator = Agent[:input_generator].new(@ts_server, 1..100, "a")
      generator.thread.join
      @ts_server.count_tuple(Tuple[:data].any).should == 100
      should.not.raise(Rinda::RequestExpiredError) do
        (1..100).each do |i|
          tuple = Tuple[:data].new(path: "input/#{i}.a", time: nil)
          @ts_server.read(tuple, 0)
        end
      end
    end
  end
end
