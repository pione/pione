require 'tmpdir'
require 'innocent-white/test-util'
require 'innocent-white/tuple'
require 'innocent-white/agent/input-generator'

include InnocentWhite
Thread.abort_on_exception = true

describe "InputGenerator" do
  describe "SimpleGeneratorMethod" do
    before do
      @remote_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3))
      @ts_server = DRbObject.new(nil, @remote_server.uri)
    end

    it 'should provide data by simple generator' do
      generator = Agent[:input_generator].new_by_simple(@ts_server, 1..10, "a", 11..20)
      generator.wait_till(:terminated)
      check_exceptions(@ts_server)
      @ts_server.count_tuple(Tuple[:data].any).should == 10
      should.not.raise(Rinda::RequestExpiredError) do
        (1..10).each do |i|
          tuple = Tuple[:data].new(name: "#{i}.a", domain: "/")
          data = @ts_server.read(tuple, 0)
          data.value.should == i + 10
        end
      end
    end

    it 'should provide file in a directory by dir generator(value mode)' do
      Dir.mktmpdir do |dir|
        File.open(File.join(dir, "1.a"), "w+"){|out| out.write("11") }
        File.open(File.join(dir, "2.b"), "w+"){|out| out.write("22") }
        File.open(File.join(dir, "3.c"), "w+"){|out| out.write("33") }
        generator = Agent[:input_generator].new_by_dir(@ts_server, dir, false)
        generator.wait_till(:terminated)
        check_exceptions(@ts_server)
        @ts_server.count_tuple(Tuple[:data].any).should == 3
        should.not.raise(Rinda::RequestExpiredError) do
          (1..3).each do |i|
            tuple = Tuple[:data].new(name: "#{i}.#{(i+96).chr}", domain: "/")
            data = @ts_server.read(tuple, 0)
            data.value.should == "#{i}#{i}"
            data.path.should.be.nil
          end
        end
      end
    end

    it 'should provide file in a directory by dir generator(path mode)' do
      Dir.mktmpdir do |dir|
        File.open(File.join(dir, "1.a"), "w+"){|out| out.write("11") }
        File.open(File.join(dir, "2.b"), "w+"){|out| out.write("22") }
        File.open(File.join(dir, "3.c"), "w+"){|out| out.write("33") }
        generator = Agent[:input_generator].new_by_dir(@ts_server, dir, true)
        generator.wait_till(:terminated)
        check_exceptions(@ts_server)
        @ts_server.count_tuple(Tuple[:data].any).should == 3
        should.not.raise(Rinda::RequestExpiredError) do
          (1..3).each do |i|
            tuple = Tuple[:data].new(name: "#{i}.#{(i+96).chr}", domain: "/")
            data = @ts_server.read(tuple, 0)
            data.path.should == File.join(dir, data.name)
            data.value.should.be.nil
          end
        end
      end
    end

  end
end
