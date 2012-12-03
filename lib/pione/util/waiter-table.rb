module Pione
  module Util
    class WaiterTable
      include DRbUndumped

      def initialize
        @req_mon = {}
        @cv = {}
        @table = {}
        @waiting = {}
        @mon = Mutex.new
      end

      def push(req_id, val)
        @req_mon[req_id] ||= Mutex.new
        @mon.synchronize {@table[req_id] = val}
        @cv[req_id].broadcast if @cv[req_id]
      end

      def take(req_id, msg_id, args)
        @req_mon[req_id] ||= Mutex.new
        @waiting[req_id] = msg_id
        @req_mon[req_id].synchronize do
          unless @table.has_key?(req_id)
            @cv[req_id] = ConditionVariable.new
            @cv[req_id].wait(@req_mon[req_id])
          end
          @cv.delete(req_id)
          @req_mon.delete(req_id)
          @waiting.delete(req_id)
          val = nil
          @mon.synchronize {val = @table.delete(req_id)}
          return val
        end
      end

      def to_s
        @mon.synchronize do
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
