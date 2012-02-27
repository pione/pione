require 'tmpdir'
require 'innocent-white/test-util'
require 'innocent-white/tuple'
require 'innocent-white/agent/input-generator'

describe "InputGenerator" do
  before do
    @ts_server = create_remote_tuple_space_server
  end

  it 'should provide data by simple generator' do
    generator = Agent[:input_generator].new_by_simple(@ts_server, "*.a", 1..10, 11..20)
    generator.wait_till(:terminated)
    check_exceptions
    count_tuple(Tuple[:data].any).should == 10
    should.not.raise(Rinda::RequestExpiredError) do
      (1..10).each do |i|
        tuple = Tuple[:data].new(name: "#{i}.a", domain: "/input")
        data = read(tuple, 0)
        should.not.raise(Resource::NotFound) do
          Resource[URI(data.uri)].read.should == (i + 10).to_s
        end
      end
    end
  end

  it 'should provide file in a directory by dir generator' do
    Dir.mktmpdir do |dir|
      File.open(File.join(dir, "1.a"), "w+"){|out| out.write("11") }
      File.open(File.join(dir, "2.b"), "w+"){|out| out.write("22") }
      File.open(File.join(dir, "3.c"), "w+"){|out| out.write("33") }
      generator = Agent[:input_generator].new_by_dir(@ts_server, dir)
      generator.wait_till(:terminated)
      check_exceptions
      count_tuple(Tuple[:data].any).should == 3
      should.not.raise(Rinda::RequestExpiredError) do
        (1..3).each do |i|
          tuple = Tuple[:data].new(name: "#{i}.#{(i+96).chr}", domain: "/input")
          data = read(tuple, 0)
          should.not.raise(Resource::NotFound) do
            Resource[URI(data.uri)].read.should == "#{i}#{i}"
          end
        end
      end
    end
  end
end
