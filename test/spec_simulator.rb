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
      gen_method = Simulator::SimpleInputGeneratorMethod.new(1..100, "a", 101..200)
      generator = Agent[:input_generator].new(@ts_server, gen_method)
      generator.thread.join
      @ts_server.count_tuple(Tuple[:data].any).should == 100
      should.not.raise(Rinda::RequestExpiredError) do
        (1..100).each do |i|
          tuple = Tuple[:data].new(name: "#{i}.a", path: "/")
          data = @ts_server.read(tuple, 0).to_tuple
          data.raw.should == i + 100
        end
      end
    end
  end
end
