require 'bacon'
require 'pione'

module TestUtil
  include Pione::TupleSpaceServerInterface

  DIR = Location[File.dirname(__FILE__)]

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

  def create_tuple_space_server
    # make drb server and it's connection
    tuple_space_server = Pione::TupleSpace::TupleSpaceServer.new({}, false)
    # base location
    base_location = Location[Temppath.create]
    tuple_space_server.write(Tuple[:base_location].new(base_location))
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

module TestUtil
  class CommandResult < StructX
    member :exception
    member :stdout
    member :stderr

    def success?
      exception.kind_of?(SystemExit) and exception.success?
    end

    def report
      unless success?
        puts "ERROR: %s" % exception.message
        exception.backtrace.each do |line|
          puts "TRACE: %s" % line
        end
        puts stdout.string[0..100] if stdout.string.size > 0
        puts stderr.string[0..100] if stderr.string.size > 0
      end
    end
  end

  module Command
    class << self
      def execute(&b)
        res = CommandResult.new(stdout: StringIO.new("", "w"), stderr: StringIO.new("", "w"))
        $stdout = res.stdout
        $stderr = res.stderr
        begin
          b.call
        rescue Object => e
          res.exception = e
        end
        $stdout = STDOUT
        $stderr = STDERR
        return res
      end

      def succeed(&b)
        res = execute(&b)
        res.report
        res.should.success
        return res
      end

      def fail(&b)
        res = execute(&b)
        res.should.not.success
        return res
      end
    end
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
    parser = Pione::Parser::DocumentParser
    basename = File.basename(rb, ".rb")
    path = File.join(File.dirname(rb), basename + ".yml")
    YAML.load(File.read(path)).each do |name, testcase|
      context.describe name do
        if strings = testcase["valid"]
          strings.each do |string|
            it "should parse as %s:%s%s" % [name, string.include?("\n") ? "\n" : " ", string.chomp] do
              should.not.raise(Parslet::ParseFailed) do
                parser.new.send(name).parse(string)
              end
            end
          end
        end

        if strings = testcase["invalid"]
          strings.each do |string|
            it "should fail when parsing as %s:%s%s" % [name, string.include?("\n") ? "\n" : "", string.chomp] do
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
  class TestCase < StructX
    member :string
    member :expected
  end

  class TestCaseEq < StructX
    member :string
    member :expected
  end

  def spec(name, parser, context, &b)
    testcases = Array.new

    def testcases.tc(obj)
      case obj
      when Hash
        obj.each do |key, val|
          push(TestCaseEq.new(key, val))
        end
      else
        push(TestCaseEq.new(obj, yield))
      end
    end

    def testcases.transform(obj, &b)
      push(TestCase.new(obj, b))
    end

    testcases.instance_eval(&b)
    context.describe name do
      testcases.each do |tc|
        it "should get %s:%s%s" % [name, tc.string.include?("\n") ? "\n" : " ", tc.string.chomp] do
          res = DocumentTransformer.new.apply(
            DocumentParser.new.send(parser).parse(tc.string)
          )
          case tc
          when TestCaseEq
            res.should == tc.expected
          when TestCase
            tc.expected.call(res)
          end
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
end

# Bacon::Context extension.
class Bacon::Context
  # Install utilities.
  include TestUtil

  def transformer_spec(name, parser_name, &b)
    TestUtil::Transformer.spec(name, parser_name, self, &b)
  end
end

module TestUtil
  # Test pione method.
  def test_pione_method(name)
    yamlname = 'spec_%s.yml' % name
    ymlpath = File.join(File.dirname(__FILE__), 'model', yamlname)
    testcases = YAML.load_file(ymlpath)

    describe "pione method test cases" do
      testcases.each do |testcase|
        expect = testcase.keys.first
        expr = testcase[expect].to_s
        expect = expect.to_s
        vtable = VariableTable.new
        it '%s should be %s' % [expr, expect] do
          expect = DocumentTransformer.new.apply(DocumentParser.new.expr.parse(expect))
          expr = DocumentTransformer.new.apply(DocumentParser.new.expr.parse(expr))
          expect.eval(vtable).should == expr.eval(vtable)
        end
      end
    end
  end

  # Test uri scheme.
  def test_uri_scheme(name)
    yamlname = 'spec_%s.yml' % name
    ymlpath = File.join(File.dirname(__FILE__), 'uri-scheme', yamlname)
    testcases = YAML.load_file(ymlpath)

    describe "uri scheme test cases" do
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
