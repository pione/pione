require 'drb'

class TestService
  include DRbUndumped

  def test
    "abc"
  end

  def pid
    Process.pid
  end
end

uri = "druby://localhost:33333"

pid1 = Process.fork do
  puts "child: #{Process.pid}"
  ts = TestService.new
  DRb.start_service(uri, ts)
  p ts.pid
  sleep 10
  Process.daemon
  puts "aaaaaaaaaaaaaaaaaaaaa"
end

sleep 1

ref = DRbObject.new_with_uri(uri)
puts ref.pid

#DRb.remove_server(server)
sleep 1

