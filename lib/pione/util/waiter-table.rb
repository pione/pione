module Pione
  module Util
    class WaiterTable
      include DRbUndumped

      def initialize
        @mutex = Mutex.new
        @table = {}
        @waiting_thread = {}
      end

      def push(req_id, val)
        @mutex.synchronize {@table[req_id] = val}
        thread = @mutex.synchronize {@waiting_thread[req_id]}
        if thread && thread.status == "sleep"
          thread.run
        end
      end

      def take(req_id, msg_id, args)
        unless @mutex.synchronize {@table.has_key?(req_id)}
          @mutex.synchronize {@waiting_thread[req_id] = Thread.current}
          Thread.stop
          @mutex.synchronize {@waiting_thread.delete(req_id)}
        end
        return @mutex.synchronize {@table.delete(req_id)}
      end

      def to_s
        @mutex.synchronize do
          table = convert_string(@table)
          waiting = convert_string(@waiting)
          "#<WaiterTable @table=%s @waiting=%s>" % [table, waiting]
        end
      end

      def convert_string(obj)
        case obj
        when Hash
          "{%s}" % obj.map do |k,v|
            "%s=>%s" % [convert_string(k), convert_string(v)]
          end.join(", ")
        when Array
          "[%s]" % obj.map{|elt| convert_string(elt)}.join(", ")
        when DRbObject
          "#<DRbObject @drburi=%s, @drbref=%s>" % [obj.__drburi, obj.__drbref]
        else
          obj.inspect
        end
      end
    end
  end
end
