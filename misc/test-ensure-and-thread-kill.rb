
list = []

def make_thread(list)
  th = Thread.new do
    begin
      while true do
        sleep 100
      end
    ensure
      sleep 0.01
      list << th.object_id
    end
  end
end

def kill_threads(threads)
  threads.list.each do |th|
    th.kill
    th.kill
    th.kill
  end
  if threads.list.map{|th| th.alive?}.include?(true)
    kill_threads(threads)
  end
end

threads = ThreadGroup.new
1..100.times do
  threads.add make_thread(list)
end
kill_threads(threads)

while threads.list.map{|th| th.alive?}.include?(true)
  sleep 1
end

sleep 10

puts "size: #{list.size}"
