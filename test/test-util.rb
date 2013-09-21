require 'bacon'
require 'pione'

Pione::Global.git_package_directory = Pione::Location[Temppath.mkdir]

module TestUtil
  include Pione
  include TupleSpaceServerInterface

  DIR = Location[File.dirname(__FILE__)]
  TEST_DATA_DIR = DIR + "test-data"
  TEST_PACKAGE_DIR = TEST_DATA_DIR + "package"

  def write_and_wait_to_be_taken(tuple, sec=5)
    observer = notify('take', tuple)
    write(tuple)
    timeout(sec) do
      observer.pop
    end
  end

  def clear_exceptions
    server = get_tuple_space_server
    server.read_all(Tuple[:exception].any).each do |tuple|
      ts_server.take(tuple)
    end
  end

  def check_exceptions
    exceptions = tuple_space_server.read_all(Pione::Tuple[:exception].any)
    exceptions.each do |tuple|
      e = tuple.value
      Bacon::ErrorLog << "#{e.class}: #{e.message}\n"
      e.backtrace.each_with_index { |line, i| Bacon::ErrorLog << "\t#{line}\n" }
      Bacon::ErrorLog << "\n"
    end
    exceptions.should.be.empty
  end

  def observe_exceptions(sec=5, &b)
    @thread = Thread.new { b.call }
    begin
      timeout(sec) do
        while @thread.alive? do; sleep 0.1; end
      end
    ensure
      check_exceptions
    end
  end

  def create_tuple_space_server
    # make drb server and it's connection
    tuple_space_server = Pione::TupleSpace::TupleSpaceServer.new({}, false)
    # base location
    base_location = Location[Temppath.create]
    tuple_space_server.write(Pione::Tuple[:base_location].new(base_location))
    # set default tuple space server
    set_tuple_space_server tuple_space_server
    # return the connection
    return tuple_space_server
  end

  def create_remote_tuple_space_server
    # make drb server and it's connection
    tuple_space_server = Pione::TupleSpace::TupleSpaceServer.new
    # base uri
    tuple_space_server.write(Tuple[:base_location].new("local:#{Dir.mktmpdir('pione-test')}/"))
    @__remote_drb_server__ = DRb::DRbServer.new(nil, tuple_space_server)
    server = DRbObject.new_with_uri(@__remote_drb_server__.uri)
    # set default tuple space server
    set_tuple_space_server server
    # return the connection
    return server
  end

  def remote_drb_server
    @__remote_drb_server__
  end
end

# Hash extension.
class Hash
  # Symbolizes hash's keys recuirsively. This is convinient for YAML handling.
  def symbolize_keys
    each_with_object({}) do |(key, val), hash|
      hash[key.to_sym] = (val.kind_of?(Hash) ? val.symbolize_keys : val)
    end
  end
end

module TestUtil
  # Test uri scheme.
  def test_location_scheme(name)
    yamlname = 'spec_%s.yml' % name
    ymlpath = File.join(File.dirname(__FILE__), 'location', yamlname)
    testcases = YAML.load_file(ymlpath)

    describe "location scheme test cases" do
      testcases.each do |testcase|
        uri = testcase.keys.first
        it uri do
          testcase[uri].keys.each do |name|
            expect = testcase[uri][name]
            expect = nil if expect == "nil"
            URI.parse(uri).__send__(name).should == expect
          end
        end
      end
    end
  end
end

module Pione::TupleSpace
  class TupleSpaceServer
    # Return all tuples of the tuple space.
    def all_tuples
      tuples = []
      bag = @__ts__.instance_variable_get("@bag")
      bag.instance_variable_get("@hash").values.each do |bin|
        tuples += bin.instance_variable_get("@bin")
      end
      _tuples = tuples.map{|t| t.value}
      return _tuples
    end

    # Return take waiting tuples.
    def take_waiter
      tuples = []
      bag = @__ts__.instance_variable_get("@take_waiter")
      bag.instance_variable_get("@hash").values.each do |bin|
        tuples += bin.instance_variable_get("@bin")
      end
      _tuples = tuples.map{|t| t.value}
      return _tuples
    end
  end
end

#
# load test utilities
#
require_relative "test-util/command"
require_relative "test-util/parser"
require_relative "test-util/transformer"
require_relative "test-util/lang"
require_relative "test-util/package"
require_relative "test-util/webserver"
require_relative "test-util/pione-method"
require_relative "test-util/tuple"

#
# extend bacon's context
#
class Bacon::Context
  include TestUtil::Transformer::Interface
  include TestUtil
end

#
# setup_for_test
#
include Pione
Thread.abort_on_exception = true
