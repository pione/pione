require 'innocent-white/test-util'
require 'innocent-white/tuple-space-server'
require 'innocent-white/tuple-space-provider'

DRb.stop_service
#DRb.current_server

describe 'TupleSpaceProvider' do
  before do
    DRb.start_service
    @kill_target = []
  end

  after do
    TupleSpaceProvider.instance.shutdown
    @kill_target.each do |pid|
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

  it 'should shutdown' do
    TupleSpaceProvider.instance.shutdown
    remote = DRbObject.new_with_uri(TupleSpaceProvider::PROVIDER_URI)
    should.raise { remote.uuid }
  end

  it 'should move provider' do
    TupleSpaceProvider.instance.shutdown
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

    @kill_target << pid1
    sleep 2
    # create child pid2 (provider in pid1 still)
    @kill_target << pid2
    # kill pid1 and move the provider to pid2
    TupleSpaceProvider.instance.pid.should == pid1
    @kill_target << pid3
    TupleSpaceProvider.instance.pid.should == pid1
  end

  it "should add tuple space server" do
    ts_server = TupleSpaceServer.new(task_worker_resource: 4)
    provider = TupleSpaceProvider.instance
    provider.add(ts_server)
    provider.tuple_space_servers.map{|ts| ts.uuid}.first.should == ts_server.uuid
  end
end

