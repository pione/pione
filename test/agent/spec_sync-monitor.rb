require_relative '../test-util'
require 'pione/document'
require 'pione/agent/sync-monitor'

describe 'Agent::SyncMonitor' do
  before do
    create_remote_tuple_space_server
    @base_uri = read(Tuple[:base_uri].any).uri
    @doc = Document.parse(<<-DOCUMENT)
      Rule test
        input 'test.a'
        output 'test.b'
      Flow---
      ---End
    DOCUMENT
    @flow = @doc['test']
    generator = Agent[:input_generator].start_by_simple(tuple_space_server, "test-*.a", 1..3, 1..3)
    generator.wait_till(:terminated)
  end

  it 'should take sync_target type tuple' do
    # make handler
    test1 = read(Tuple[:data].new(name: 'test-1.a'))
    handler = @flow.make_handler(tuple_space_server, [test1], [])

    # make sync_target
    tuple1 = Tuple[:sync_target].new(src: 'test_src', dest: handler.domain, name: 'test-1.b')
    tuple2 = Tuple[:sync_target].new(src: 'test_src', dest: handler.domain, name: 'test-2.b')
    tuple3 = Tuple[:sync_target].new(src: 'test_src', dest: handler.domain, name: 'test-3.b')
    [tuple1, tuple2, tuple3].each {|t| write(t) }

    # monitor
    monitor = Agent[:sync_monitor].start(tuple_space_server, handler)
    monitor.wait_until_count(4, :sync_target_waiting) do
      monitor.start
    end
    monitor.queue.size.should == 3
    monitor.queue.should.include tuple1
    monitor.queue.should.include tuple2
    monitor.queue.should.include tuple3
  end

  #it 'should write finished and data tuples' do
  #  
  #end
end
