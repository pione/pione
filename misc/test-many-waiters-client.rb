require 'drb/drb'
require 'rinda/rinda'

Thread.abort_on_exception = true

module DRb
  class DRbConn
    @table = {}
    def self.open(remote_uri)  # :nodoc:
      begin
        conn = nil

        @mutex.synchronize do
          cache = @table[remote_uri]
          if not(cache.nil?) && cache.alive?
            conn = cache
          else
            puts "new"
            cache.close unless cache.nil?
            conn = self.new(remote_uri) unless conn
            @table[remote_uri] = conn
          end
        end

        succ, result = yield(conn)
        return succ, result

      ensure
        if conn
          if succ
            puts "succ"
          else
            conn.close
          end
        end
      end
    end
  end
end

DRb.start_service

ts = DRbObject.new_with_uri('druby://localhost:30000')
$count = 0
10000.times do
  Thread.new do
    $count += 1
    ts.take([:a])
  end
end

loop do
  break if $count == 10000
  puts $count
  sleep 1
end
