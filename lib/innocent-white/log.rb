require 'innocent-white/common'
require 'time'

module InnocentWhite
  class Log

    # Define log structure's item.
    def self.item(name)
      define_method(name) do
        @data[name]
      end
    end

    def initialize(data)
      @data = data
    end

    item :application
    item :component
    item :subcomponents
    item :attribute
    item :value

    def to_s
      logid = generate_logid
      time = Time.now.iso8601
      attr = [application,component,subcomponents,attribute].flatten.join(".")
    end

    IDCHAR = ("A".."Z").to_a + (0..9).to_a

    def generate_logid(i=4)
      i > 0 ? rand(IDCHAR.size) + generate_logid(i-1) : ""
    end
  end
end
