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

  def create_tuple_space_server
    # make drb server and it's connection
    tuple_space_server = Pione::TupleSpace::TupleSpaceServer.new
    # base uri
    tuple_space_server.write(Tuple[:base_location].new("local:#{Dir.mktmpdir('pione-test')}/"))
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
        it "should get %s:%s%s" % [name, tc.string.include?("\n") ? "\n" : " ", tc.string.chomp] do
          res = DocumentTransformer.new.apply(
            DocumentParser.new.send(parser).parse(tc.string)
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
  def test_pione_method(name)
    #
    # test cases
    #
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

begin
  require 'em-ftpd'
  require 'pione/patch/em-ftpd-patch'

  module EM::FTPD::Files
    def puts(*args)
      # ignored
    end
  end
rescue

end


module TestUtil
  class FTPServer
    class AuthInfo
      attr_reader :user
      attr_reader :password

      def initialize
        @user = Pione::Util.generate_uuid
        @password = Pione::Util.generate_uuid
      end
    end

    class OnMemoryFS
      attr_reader :directory
      attr_reader :file
      attr_reader :mtime

      def initialize
        @directory = {"/" => Set.new}
        @file = {}
        @mtime = {}
      end

      def clear
        @directory.clear
        @directory["/"] = Set.new
        @file.clear
        @mtime.clear
      end
    end

    PORT = 39123
    AUTH_INFO = AuthInfo.new
    FS = OnMemoryFS.new

    class << self
      def enabled?
        begin
          require 'em-ftpd'
          return true
        rescue
          return false
        end
      end

      # Start FTP server.
      def start
        FS.clear
        @thread = Thread.new do
          EventMachine.run do
            EventMachine.start_server("0.0.0.0", PORT, EM::FTPD::Server, self)
          end
        end
      end

      def stop
        FS.clear
        EventMachine.stop
        @thread.kill if @thread
      end

      def make_location(path)
        Location["ftp://%s:%s@localhost:%i%s" % [AUTH_INFO.user, AUTH_INFO.password, PORT, path]]
      end
    end

    def initialize
      @directory = FS.directory
      @file = FS.file
      @mtime = FS.mtime
      @user = AUTH_INFO.user
      @password = AUTH_INFO.password
    end

    def change_dir(path, &b)
      yield @directory.keys.include?(path)
    end

    def dir_contents(path, &b)
      if @directory.has_key?(path) and @directory[path]
        entries = @directory[path].map do |entry|
          entry_path = Pathname.new(File.join(path, entry)).cleanpath.to_s
          if @directory.has_key?(entry_path)
            dir_item(entry)
          else
            file_item(entry, @file[entry_path].size)
          end
        end
        yield entries
      else
        yield Set.new
      end
    end

    def authenticate(user, password, &b)
      # yield @user == user && @password == password
      yield true
    end

    def bytes(path, &b)
      path = Pathname.new(path).cleanpath.to_s
      if @file.has_key?(path)
        yield @file[path].size
      elsif @directory.has_key?(path)
        yield -1
      else
        yield false
      end
    end

    def get_file(path, &block)
      path = Pathname.new(path).cleanpath.to_s
      if @file.has_key?(path)
        yield @file[path]
      else
        yeild false
      end
    end

    def put_file(path, data, &b)
      path = Pathname.new(path).cleanpath
      dir = path.dirname.to_s
      filename = path.basename.to_s
      if @directory.has_key?(dir) and filename
        @directory[dir] << filename
        @file[path.to_s] = File.read(data)
        @mtime[path.to_s] = Time.now
        yield data.size
      else
        yield false
      end
    end

    def delete_file(path, &b)
      path = Pathname.new(path).cleanpath
      dir = path.dirname.to_s
      filename = path.basename.to_s
      if @directory.has_key?(dir) and @directory[dir].include?(filename)
        @directory[dir].delete(dir)
        @file.delete(path.to_s)
        @mtime.delete(path.to_s)
        yield true
      else
        yield false
      end
    end

    def rename_file(from, to, &b)
      from_path = Pathname.new(from).cleanpath
      from_dir = from_path.dirname.to_s
      from_filename = from_path.basename.to_s
      to_path = Pathname.new(to).cleanpath
      to_dir = to_path.dirname.to_s
      to_filename = to_path.basename.to_s
      if @file.has_key?(from_path.to_s) && @directory.has_key?(to_dir)
        data = @file[from_path.to_s]
        @file.delete(from_path.to_s)
        @directory[from_dir].delete(from_filename)
        @file[to_path.to_s] = data
        @directory[to_dir] << to_filename
        yield true
      else
        yield false
      end
    end

    def make_dir(path, &b)
      path = Pathname.new(path).cleanpath
      dir = path.dirname.to_s
      basename = path.basename.to_s
      if @directory.has_key?(path.to_s) or not(@directory.has_key?(dir))
        yield false
      else
        @directory[path.to_s] = Set.new
        @directory[dir] << basename
        yield true
      end
    end

    def mtime(path)
      path = Pathname.new(path).cleanpath.to_s
      if @file[path]
        yield @mtime[path]
      else
        yield false
      end
    end

    private

    def dir_item(name)
      EM::FTPD::DirectoryItem.new(:name => name, :directory => true, :size => 0)
    end

    def file_item(name, bytes)
      EM::FTPD::DirectoryItem.new(:name => name, :directory => false, :size => bytes)
    end
  end
end

def setup_for_test
  include Pione
  Thread.abort_on_exception = true
end

setup_for_test
