require 'benchmarkx'
require 'innocent-white/tuple-space-server'

#
# apt-get install rmagic
# gem install rmagic
# gem install benchmarkx
#

$ts_server = InnocentWhite::TupleSpaceServer.new(task_worker_resource: 4)

def write(n)
  n.times do |i|
    $ts_server.write([:test, i])
  end
end

def take(n)
  n.times do |i|
    $ts_server.take([:test, i])
  end
end

def write_and_take(n)
  write(n)
  take(n)
end

include BenchmarkX
benchmark("       " + CAPTION, 7, FMTSTR) do |x|
  x.filename = "example/write_and_take_test.png"
  x.gruff.title = "write and take test"
  [500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000].each do |i|
    x.report("#{i}:")   {write_and_take(i)}
  end
end
