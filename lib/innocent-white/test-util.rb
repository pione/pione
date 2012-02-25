require 'bacon'
require 'innocent-white/common'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'

module InnocentWhite
  module TestUtil
    include InnocentWhite::TupleSpaceServerInterface

    def write_and_wait_to_be_taken(tuple, sec=5)
      ts_server = get_tuple_space_server
      observer = notify('take', tuple)
      write(tuple)
      timeout(sec) do
        observer.pop
      end
    end

    def clear_exceptions
      ts_server = get_tuple_space_server
      ts_server.read_all(Tuple[:exception].any).each do |tuple|
        ts_server.take(tuple)
      end
    end

    def check_exceptions
      ts_server = get_tuple_space_server
      exceptions = ts_server.read_all(Tuple[:exception].any)
      exceptions.each do |tuple|
        e = tuple.value
        Bacon::ErrorLog << "#{e.class}: #{e.message}\n"
        e.backtrace.each_with_index { |line, i|
          Bacon::ErrorLog << "\t#{line}\n"
        #  Bacon::ErrorLog << "\t#{line}#{i==0 ? ": #@name - #{description}" : ""}\n"
        }
        Bacon::ErrorLog << "\n"
      end
      exceptions.should.be.empty
    end

    def create_remote_tuple_space_server
      # base uri
      uri = "local:#{Dir.mktmpdir('innocent-white-')}/"
      # make drb server and it's connection
      drb_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3, base_uri: uri))
      server = DRbObject.new(nil, drb_server.uri)
      # set default tuple space server
      set_tuple_space_server server
      # return the connection
      return server
    end
  end
end

# Install utilities.
class Bacon::Context
  include InnocentWhite::TestUtil
end

def setup_test
  include InnocentWhite
  Thread.abort_on_exception = true
end

setup_test
