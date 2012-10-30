require 'drb/drb'
require 'rinda/rinda'
require 'rinda/tuplespace'

ts = Rinda::TupleSpace.new
DRb.start_service('druby://localhost:30000', ts)
Thread.new do
  loop do
    p DRb::DRbConn.instance_variable_get(:@pool)
    sleep 1
  end
end

DRb.thread.join
