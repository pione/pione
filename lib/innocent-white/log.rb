require 'innocent-white/common'
require 'time'

module InnocentWhite
  class Log

    # Log::Record is a key-value line for log. A record consisted of following items:
    # - application
    # - component
    # - key
    # - value
    class Record
      attr_reader :components
      attr_reader :key
      attr_reader :value

      def initialize(components, key, value)
        @components = components.kind_of?(Array) ? components : [components]
        @key = key
        @value = value
      end

      def application
        "innocent-white"
      end

      # Format as a string.
      # i.e.
      #   A35D[2012-04-25T14:48:57.791+09:00] innocent-white.rule-provider.status: initialized
      def format(logid, time)
        resource = [application, components, key].flatten.compact.join(".")
        "%s[%s] %s: %s" % [logid, time, resource, value]
      end
    end

    attr_reader :records

    # Log is a representation for logging.
    # i.e.
    #   Log.new do
    #     add_record(component: "tuple-space-server",
    #                key: "action",
    #                value: "start")
    #   end
    #
    def initialize
      @records = []
      yield self if block_given?
    end

    def add_record(*args)
      @records << Record.new(*args)
    end


    # Format as string.
    # i.e.
    #   A35D[2012-04-25T14:48:57.791+09:00] innocent-white.task-worker.action: "take_task"
    #   A35D[2012-04-25T14:48:57.791+09:00] innocent-white.task-worker.object: ...
    def format
      logid = generate_logid
      time = Time.now.iso8601(3)
      @records.map{|record| record.format(logid, time)}.join("\n")
    end

    private

    IDCHAR = ("A".."Z").to_a + (0..9).to_a.map{|i|i.to_s}

    def generate_logid(i=4)
      i > 0 ? IDCHAR[rand(IDCHAR.size)] + generate_logid(i-1) : ""
    end
  end
end
