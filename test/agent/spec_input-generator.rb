require_relative '../test-util'

describe "Pione::Agent::InputGenerator" do
  before do
    @orig = Global.input_generator_stream_check_timespan
    DRb.start_service
    create_remote_tuple_space_server
    Global.input_generator_stream_check_timespan = 0.1
  end

  after do
    DRb.stop_service
    Global.input_generator_stream_check_timespan = @orig
  end

  describe 'dir generator' do
    it 'should generate inputs from files in the directory' do
      Dir.mktmpdir do |dir|
        # make local uri
        uri = URI.parse("local:%s" % dir).as_directory

        # create input files
        Resource[uri + "1.a"].create("11")
        Resource[uri + "2.b"].create("22")
        Resource[uri + "3.c"].create("33")

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start_by_dir(tuple_space_server, uri)
        generator.wait_till(:terminated)

        # check exceptions
        check_exceptions

        # check data
        count_tuple(Tuple[:data].any).should == 3
        should.not.raise(Rinda::RequestExpiredError) do
          (1..3).each do |i|
            tuple = Tuple[:data].new(name: "#{i}.#{(i+96).chr}", domain: "input")
            data = read(tuple, 0)
            should.not.raise(Resource::NotFound) do
              Resource[URI(data.uri)].read.should == "#{i}#{i}"
            end
          end
        end
      end
    end
  end

  describe 'with stream generator' do
    it 'should stream' do
      Dir.mktmpdir do |dir|
        # make local uri
        uri = URI.parse("local:%s" % dir).as_directory

        # create input files
        Resource[uri + "1.a"].create("11")
        Resource[uri + "2.b"].create("22")
        Resource[uri + "3.c"].create("33")

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start_by_stream(tuple_space_server, uri)
        generator.should.stream
        generator.terminate
      end
    end

    it 'should provide files in a directory by stream generator' do
      Dir.mktmpdir do |dir|
        ## initial inputs
        # make local uri
        uri = URI.parse("local:%s" % dir).as_directory

        # create input files
        Resource[uri + "1.a"].create("11")
        Resource[uri + "2.b"].create("22")
        Resource[uri + "3.c"].create("33")

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start_by_stream(tuple_space_server, uri)
        generator.wait_till(:sleeping)

        # check exceptions
        check_exceptions

        # check data
        count_tuple(Tuple[:data].any).should == 3

        ## an addtional input
        # create additional files
        Resource[uri + "4.d"].create("44")
        sleep 0.2
        generator.wait_till(:sleeping)

        # check exceptions
        check_exceptions

        # check data
        count_tuple(Tuple[:data].any).should == 4

        # create additional files
        Resource[uri + "5.e"].create("55")
        sleep 0.2
        generator.wait_till(:sleeping)

        # check exceptions
        check_exceptions

        # check data
        count_tuple(Tuple[:data].any).should == 5

        should.not.raise(Rinda::RequestExpiredError) do
          (1..3).each do |i|
            tuple = Tuple[:data].new(name: "#{i}.#{(i+96).chr}", domain: "input")
            data = read(tuple, 0)
            should.not.raise(Resource::NotFound) do
              Resource[URI(data.uri)].read.should == "#{i}#{i}"
            end
          end
        end
      end
    end
  end
end
