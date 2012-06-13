require 'tmpdir'
require 'bacon'
require 'yaml'
require 'pione/common'
require 'pione/agent'
require 'pione/agent/input-generator'

module Pione
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
      ts_server = get_tuple_space_server
      ts_server.read_all(Tuple[:exception].any).each do |tuple|
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
      # base uri
      uri = "local:#{Dir.mktmpdir('pione-')}/"
      # make drb server and it's connection
      ts_server = TupleSpaceServer.new(task_worker_resource: 3, base_uri: uri)
      @__remote_drb_server__ = DRb::DRbServer.new(nil, ts_server)
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
    include Pione::TestUtil

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

class Hash
  def symbolize_keys
    each_with_object({}) do |(key, val), hash|
      hash[key.to_sym] = (val.kind_of?(Hash) ? val.symbolize_keys : val)
    end
  end
end


# Install utilities.
class Bacon::Context
  include Pione::TestUtil
end

module Pione
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

def setup_test
  include Pione
  Thread.abort_on_exception = true
end

setup_test
