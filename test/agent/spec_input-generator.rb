require_relative '../test-util'

describe "Pione::Agent::InputGenerator" do
  before do
    DRb.start_service
    create_remote_tuple_space_server
  end

  after do
    DRb.stop_service
  end

  describe 'simple generator' do
    it 'should provide data by simple generator' do
      # create generator
      generator =
        Agent[:input_generator].start_by_simple(tuple_space_server, "*.a", 1..10, 11..20)
      # wait finishing
      generator.wait_till(:terminated)
      # check exceptions
      check_exceptions
      # check data
      count_tuple(Tuple[:data].any).should == 10
      should.not.raise(Rinda::RequestExpiredError) do
        (1..10).each do |i|
          data = read0(Tuple[:data].new(name: "#{i}.a", domain: "input"))
          should.not.raise(Resource::NotFound) do
            Resource[URI(data.uri)].read.should == (i + 10).to_s
          end
        end
      end
    end
  end

  describe 'dir generator' do
    it 'should provide files in a directory by dir generator' do
      Dir.mktmpdir do |dir|
        # create input files
        File.open(File.join(dir, "1.a"), "w+"){|out| out.write("11") }
        File.open(File.join(dir, "2.b"), "w+"){|out| out.write("22") }
        File.open(File.join(dir, "3.c"), "w+"){|out| out.write("33") }

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start_by_dir(tuple_space_server, dir)
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
        # create input files
        File.open(File.join(dir, "1.a"), "w+"){|out| out.write("11") }
        File.open(File.join(dir, "2.b"), "w+"){|out| out.write("22") }
        File.open(File.join(dir, "3.c"), "w+"){|out| out.write("33") }

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start_by_stream(tuple_space_server, dir)
        generator.should.stream
        generator.terminate
      end
    end

    it 'should provide files in a directory by stream generator' do
      Dir.mktmpdir do |dir|
        ## initial inputs
        # create input files
        File.open(File.join(dir, "1.a"), "w+"){|out| out.write("11") }
        File.open(File.join(dir, "2.b"), "w+"){|out| out.write("22") }
        File.open(File.join(dir, "3.c"), "w+"){|out| out.write("33") }

        # make generator and wait to finish it's job
        generator = Agent[:input_generator].start_by_stream(tuple_space_server, dir)
        generator.wait_till(:sleeping)

        # check exceptions
        check_exceptions

        # check data
        count_tuple(Tuple[:data].any).should == 3

        ## an addtional input
        # create additional files
        File.open(File.join(dir, "4.d"), "w+"){|out| out.write("44") }
        sleep 1
        generator.wait_till(:sleeping)

        # check exceptions
        check_exceptions

        # check data
        count_tuple(Tuple[:data].any).should == 4

        # create additional files
        File.open(File.join(dir, "5.e"), "w+"){|out| out.write("55") }
        sleep 1
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
