require 'tmpdir'
require 'bacon'
require 'innocent-white/common'
require 'innocent-white/tuple'
require 'innocent-white/tuple-space-server'
require 'innocent-white/agent'
require 'innocent-white/agent/input-generator'

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
      # base uri
      uri = "local:#{Dir.mktmpdir('innocent-white-')}/"
      # make drb server and it's connection
      @__remote_drb_server__ = DRb::DRbServer.new(nil, TupleSpaceServer.new(task_worker_resource: 3, base_uri: uri))
      server = DRbObject.new(nil, @__remote_drb_server__.uri)
      # set default tuple space server
      set_tuple_space_server server
      # return the connection
      return server
    end

    def remote_drb_server
      @__remote_drb_server__
    end
  end

  class Agent::Base
    include InnocentWhite::TestUtil

    alias :set_current_state_orig :set_current_state
    def set_current_state(state)
      set_current_state_orig(state)
      if @__counter__
        @__counter__.has_key?(state) ? @__counter__[state] += 1 : @__counter__[state] = 1
      end
    end

    def wait_until_count(number, state, sec=5, &b)
      timeout(sec) do
        @__counter__ = {}
        b.call
        p get_tuple_space_server.all_tuples
        while @__counter__[state].nil? or @__counter__[state] < number do
          p current_state
          #p self
          #p get_tuple_space_server.all_tuples
          check_exceptions
          sleep 0.1
        end
        @__counter__ = nil
      end
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
