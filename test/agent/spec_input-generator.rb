require 'pione/test-helper'

describe "Pione::Agent::InputGenerator" do
  before do
    @orig = Global.input_generator_stream_check_timespan
    @tuple_space = TestHelper::TupleSpace.create(self)
    Global.input_generator_stream_check_timespan = 0.1
    @base_location = read!(Pione::Tuple[:base_location].new).location
  end

  after do
    @tuple_space.terminate
    Global.input_generator_stream_check_timespan = @orig
  end

  describe 'dir generator' do
    it 'should generate inputs from files in the directory' do
      Dir.mktmpdir do |dir|
        # make local location
        dir = Location["local:%s" % dir]

        # create input files
        (dir + "1.a").create("11")
        (dir + "2.b").create("22")
        (dir + "3.c").create("33")

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start(@tuple_space, :dir, dir, false)
        generator.wait_until_terminated

        # check exceptions
        TestHelper::TupleSpace.check_exceptions(@tuple_space)

        generator.terminate

        # check data
        count_tuple(Tuple[:data].any).should == 3
        read!(Tuple[:data].new(name: "1.a", location: @base_location + "input" + "1.a", domain: "root")).location.read.should == "11"
        read!(Tuple[:data].new(name: "2.b", location: @base_location + "input" + "2.b", domain: "root")).location.read.should == "22"
        read!(Tuple[:data].new(name: "3.c", location: @base_location + "input" + "3.c", domain: "root")).location.read.should == "33"
      end
    end
  end

  describe 'with stream generator' do
    it 'should stream' do
      Dir.mktmpdir do |dir|
        # make local location
        dir = Location["local:%s" % dir]

        # create input files
        (dir + "1.a").create("11")
        (dir + "2.b").create("22")
        (dir + "3.c").create("33")

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start(tuple_space_server, :dir, dir, true)
        generator.should.stream
        generator.terminate
      end
    end

    it 'should provide files in a directory by stream generator' do
      Dir.mktmpdir do |dir|
        ## initial inputs
        # make local location
        dir = Location["local:%s" % dir]

        # create input files
        (dir + "1.a").create("11")
        (dir + "2.b").create("22")
        (dir + "3.c").create("33")

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start(tuple_space_server, :dir, dir, true)
        generator.wait_until_before(:sleep)

        # check exceptions
        TestHelper::TupleSpace.check_exceptions(@tuple_space)

        # check data
        count_tuple(Tuple[:data].any).should == 3

        ## an addtional input
        # create additional files
        (dir + "4.d").create("44")
        generator.wait_until_after(:stop_iteration)
        generator.wait_until_before(:sleep)

        # check exceptions
        TestHelper::TupleSpace.check_exceptions(@tuple_space)

        # check data
        count_tuple(Tuple[:data].any).should == 4

        # create additional files
        (dir + "5.e").create("55")
        generator.wait_until_after(:stop_iteration)
        generator.wait_until_before(:sleep)

        # check exceptions
        TestHelper::TupleSpace.check_exceptions(@tuple_space)

        generator.terminate

        # check data
        count_tuple(Tuple[:data].any).should == 5
        read!(Tuple[:data].new(name: "1.a", location: @base_location + "input" + "1.a", domain: "root")).location.read.should == "11"
        read!(Tuple[:data].new(name: "2.b", location: @base_location + "input" + "2.b", domain: "root")).location.read.should == "22"
        read!(Tuple[:data].new(name: "3.c", location: @base_location + "input" + "3.c", domain: "root")).location.read.should == "33"
        read!(Tuple[:data].new(name: "4.d", location: @base_location + "input" + "4.d", domain: "root")).location.read.should == "44"
        read!(Tuple[:data].new(name: "5.e", location: @base_location + "input" + "5.e", domain: "root")).location.read.should == "55"
      end
    end
  end
end
