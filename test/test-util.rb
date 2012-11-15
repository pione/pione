require 'bacon'
require 'pione'

module TestUtil
  include Pione::TupleSpaceServerInterface

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
    exceptions = tuple_space_server.read_all(Tuple[:exception].any)
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

  def create_remote_tuple_space_server
    # make drb server and it's connection
    tuple_space_server = Pione::TupleSpace::TupleSpaceServer.new
    # base uri
    tuple_space_server.write(Tuple[:base_uri].new("local:#{Dir.mktmpdir('pione-test')}/"))
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

module TestUtil::Parser
  # Makes a test parser class by the sub-parser module.
  def make_test_parser(parser_module)
    klass = Class.new(Parslet::Parser)
    klass.instance_eval do
      include parser_module
    end
    return klass
  end
  module_function :make_test_parser

  def spec(mod, rb, context)
    #parser = make_test_parser(mod)
    parser = Pione::Parser
    basename = File.basename(rb, ".rb")
    path = File.join(File.dirname(rb), basename + ".yml")
    YAML.load(File.read(path)).each do |name, testcase|
      context.describe name do
        if strings = testcase["valid"]
          strings.each do |string|
            it "should parse as #{name}: #{string}" do
              should.not.raise(Parslet::ParseFailed) do
                parser.new.send(name).parse(string)
              end
            end
          end
        end

        if strings = testcase["invalid"]
          strings.each do |string|
            it "should fail when parsing as #{name}: #{string}" do
              should.raise(Parslet::ParseFailed) do
                parser.new.send(name).parse(string)
              end
            end
          end
        end
      end
    end
  end
  module_function :spec
end

module TestUtil::Transformer
  TestCase = Struct.new(:string, :expected)

  def spec(name, parser, context, &b)
    testcases = Array.new
    def testcases.tc(obj)
      case obj
      when Hash
        obj.each do |key, val|
          push(TestCase.new(key, val))
        end
      else
        push(TestCase.new(obj, yield))
      end
    end
    testcases.instance_eval(&b)
    context.describe name do
      testcases.each do |tc|
        it "should get #{name}: #{tc.string}" do
          res = Transformer.new.apply(
            Parser.new.send(parser).parse(tc.string)
          )
          res.should == tc.expected
        end
      end
    end
  end
  module_function :spec
end

# Hash extension.
class Hash
  # Symbolizes hash's keys recuirsively. This is convinient for YAML handling.
  def symbolize_keys
    each_with_object({}) do |(key, val), hash|
      hash[key.to_sym] = (val.kind_of?(Hash) ? val.symbolize_keys : val)
    end
  end

  def to_params
    Parameters.new(
      Hash[map{|key, val| [Pione::Model::Variable.new(key), val.to_pione]}]
    )
  end
end

# Bacon::Context extension.
class Bacon::Context
  # Install utilities.
  include TestUtil

  def transformer_spec(name, parser_name, &b)
    TestUtil::Transformer.spec(name, parser_name, self, &b)
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

module Pione::Agent
  class BasicAgent
    include TestUtil

    # Fake set_current_state for counting state changes.
    alias :set_current_state_orig :set_current_state
    def set_current_state(state)
      @__counter__ ||= nil
      set_current_state_orig(state)
      if @__counter__
        @__counter__.has_key?(state) ? @__counter__[state] += 1 : @__counter__[state] = 1
      end
    end

    # Wait until state counter is reached at the number.
    def wait_until_count(number, state, sec=5, &b)
      timeout(sec) do
        @__counter__ = {}
        first_time = true
        while @__counter__[state].nil? or @__counter__[state] < number do
          b.call if first_time
          first_time = false
          check_exceptions
          sleep 0.2
        end
        @__counter__ = nil
      end
    end
  end
end

def setup_for_test
  include Pione
  Thread.abort_on_exception = true
end

setup_for_test
