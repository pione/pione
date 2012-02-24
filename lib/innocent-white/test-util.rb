require 'bacon'
require 'innocent-white/common'
require 'innocent-white/tuple'

module InnocentWhite
  module TestUtil
    def clear_exceptions(ts_server)
      ts_server.read_all(Tuple[:exception].any).each do |tuple|
        ts_server.take(tuple)
      end
    end

    def check_exceptions(ts_server)
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
      uri = "local:#{Dir.mktmpdir('innocent-white-')}/"
      remote_server = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3, base_uri: uri))
      DRbObject.new(nil, remote_server.uri)
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
