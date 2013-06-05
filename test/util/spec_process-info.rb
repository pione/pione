require_relative '../test-util'

def test_available?
  begin
    pid = Process.spawn("sleep", "100")
    Process.kill(:TERM, pid)
    return true
  rescue
    return false
  end
end

describe "Pione::Util::ProcessInfo" do
  if test_available?
    before do
      @pid = Process.spawn("sleep", "100")
      @thread = Process.detach(@pid)
      @info = ProcessInfo.new(@pid, @thread)
    end

    after do
      @info.kill if @info.alive?
    end

    it "should get pid" do
      @info.pid.should == @pid
    end

    it "should get process watching thread" do
      @info.thread.should == @thread
    end

    it "should be alive" do
      @info.should.alive
    end

    it "should kill the process" do
      @info.kill
      @info.should.not.alive
    end

    it "should be stopped" do
      @info.kill
      @info.should.stop
    end

    it "should wait" do
      should.raise(Timeout::Error) do
        timeout(1) {@info.wait}
      end
    end
  else
    puts "*** test of Pione::Util::ProcessInfo is not available in this environment ***"
  end
end

