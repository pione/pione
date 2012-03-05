require 'innocent-white/test-util'
require 'innocent-white/tuple-space-server'
require 'innocent-white/tuple-space-provider'

DRb.start_service

describe 'TupleSpaceProvider' do
  before do
    @kill = []
  end

  after do
    TupleSpaceProvider.instance.terminate
    # kill processes
    @kill.each do |pid|
      Process.kill('KILL', pid)
    end
  end

  it 'should get provider' do
    p1 = TupleSpaceProvider.instance
    p2 = TupleSpaceProvider.instance
    p3 = TupleSpaceProvider.instance
    p1.uuid.should == p2.uuid
    p3.uuid.should == p3.uuid
  end

  it 'should terminate' do
    p TupleSpaceProvider.instance
    puts "PID: #{TupleSpaceProvider.instance.pid}"
    puts TupleSpaceProvider.instance.uuid
    TupleSpaceProvider.instance.terminate

    child = Process.fork do
      DRb.module_eval do
        p @primary_server
        p @server
      end
      puts "Child PID: #{TupleSpaceProvider.instance.pid}"
      puts "Child UUID: #{TupleSpaceProvider.instance.uuid}"
      sleep 10
      TupleSpaceProvider.instance.terminate
    end
    @kill << child

    sleep 1
    remote = DRbObject.new_with_uri(TupleSpaceProvider::PROVIDER_URI)

    p DRb.to_obj(nil)
    DRb.module_eval do
      p @primary_server
    end

    should.raise { puts remote.uuid }
  end

  it 'should move provider' do
    TupleSpaceProvider.instance.terminate
    should.raise(DRb::DRbServerNotFound){DRb.current_server}

    # provider in pid1
    pid1 = Process.fork do
      TupleSpaceServer.new
      sleep 60
    end

    pid2 = Process.fork do
      provider = TupleSpaceProvider.instance
      sleep 60
    end

    pid3 = Process.fork do
      provider = TupleSpaceProvider.instance
      sleep 60
    end

    TupleSpaceProvider.instance.pid.should == pid1

    @kill << pid1
    sleep 2
    # create child pid2 (provider in pid1 still)
    @kill << pid2
    # kill pid1 and move the provider to pid2
    TupleSpaceProvider.instance.pid.should == pid1
    @kill << pid3
    TupleSpaceProvider.instance.pid.should == pid1
  end

  it "should add tuple space server" do
    ts_server = TupleSpaceServer.new(task_worker_resource: 4)
    provider = TupleSpaceProvider.instance
    provider.add(ts_server)
    provider.tuple_space_servers.map{|ts| ts.uuid}.first.should == ts_server.uuid
  end
end

