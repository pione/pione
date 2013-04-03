module Pione
  module Util
    # Log is a class for logging on tuple space.
    class Log
      attr_accessor :timestamp

      # Creatas a new log record.
      #
      # @param component [String]
      #   component name
      # @param data
      #   log content
      def initialize(component, data)
        @component = component
        @timestample = nil
        @data = data
      end

      # Format as JSON string.
      #
      # @return [String]
      #   JSON string
      def format
        JSON.dump({:timestamp => @timestamp.iso8601(3), :component => @component}.merge(@data))
      end
    end

    class LogFile
      def initialize(path)
        @path = path
        @data = []
        read
      end

      def read
        @path.each_line do |line|
          @data << JSON.parse(line)
        end
      end

      def group_by_uuid
        @data.inject({}) do |table, record|
          table[record["uuid"]] ||= []
          table.tap{|x| x[record["uuid"]] << record}
        end
      end
    end

    class AgentXESLogFile < LogFile
      class Extension
        attr_reader :name
        attr_reader :prefix
        attr_reader :uri

        def initialize(name, prefix, uri)
          @name = name
          @prefix = prefix
          @uri = uri
        end

        def format
          REXML::Element.new("extension").tap do |ext|
            ext.attributes["name"] = @name
            ext.attributes["prefix"] = @prefix
            ext.attributes["uri"] = @uri
          end
        end
      end

      CONCEPT = Extension.new("Concept", "concept", "http://www.xes-standard.org/concept.xesext")
      IDENTITY = Extension.new("Identity", "identity", "http://www.xes-standard.org/identity.xesext")
      TIME = Extension.new("Time", "time", "http://www.xes-standard.org/time.xesext")
      LIFECYCLE = Extension.new("Lifecycle", "lifecycle", "http://www.xes-standard.org/lifecycle.xesext")
      ORGANIZATIONAL = Extension.new("Organizational", "org", "http://www.xes-standard.org/org.xesext")

      class Classifier
        attr_reader :name
        attr_reader :keys

        def initialize(name, keys)
          @name = name
          @keys = keys
        end

        def format
          REXML::Element.new("classifier").tap do |ext|
            ext.attributes["name"] = @name
            ext.attributes["keys"] = @keys
          end
        end
      end

      MXML_LEGACY_CLASSIFIER = Classifier.new("MXML Legacy Classifier", "concept:name lifecycle:transition")
      EVENT_NAME = Classifier.new("Event Name", "concept:name")
      RESOURCE = Classifier.new("Resource", "org:resource")

      class Trace
        attr_reader :uuid
        attr_accessor :events

        def initialize(uuid, events=[])
          @uuid = uuid
          @events = events
        end

        def agent_type
          resource = @events.first.resource
        end

        def format
          events = @events.select {|e| e.valid?}
          unless events.empty?
            REXML::Element.new("trace").tap do |trace|
              trace.add_element("id", {"key" => "identity:id", "value" => @uuid})
              trace.add_element("string", {"key" => "concept:name", "value" => "%s_%s" % [agent_type, @uuid]})
              events.each {|e| trace.elements << e.format}
            end
          end
        end
      end

      class Event
        attr_reader :name
        attr_reader :resource
        attr_reader :timestamp
        attr_reader :transition

        def initialize(name, resource, timestamp, transition)
          @name = name
          @resource = resource
          @timestamp = timestamp
          @transition = transition
        end

        def valid?
          return false unless @name
          return false unless @resource
          return false unless @timestamp
          return false unless @transition
          return true
        end

        def format
          REXML::Element.new("event").tap do |event|
            event.add_element("string", {"key" => "concept:name", "value" => @name})
            event.add_element("string", {"key" => "org:resource", "value" => @resource})
            event.add_element("date", {"key" => "time:timestamp", "value" => @timestamp})
            event.add_element("string", {"key" => "lifecycle:transition", "value" => @transition})
          end
        end
      end

      def save(path)
        path.write(format.to_s)
      end

      def format(agent_type)
        REXML::Document.new.tap do |doc|
          doc.elements << make_root(agent_type)
          doc << REXML::XMLDecl.new
        end
      end

      private

      def make_root(agent_type)
        REXML::Element.new("log").tap do |log|
          log.attributes["xes.version"] = "1.4"
          log.attributes["xes.features"] = ""
          log.attributes["openxes.version"] = "1.0RC7"
          log.attributes["xmlns"] = "http://www.xes-standard.org/"
          log.elements << CONCEPT.format
          log.elements << IDENTITY.format
          log.elements << TIME.format
          log.elements << LIFECYCLE.format
          log.elements << ORGANIZATIONAL.format
          log.elements << MXML_LEGACY_CLASSIFIER.format
          log.elements << EVENT_NAME.format
          log.elements << RESOURCE.format
          log.add_element("string", {"key" => "concept:name", "value" => "PIONE agent activity log"})
          make_traces.each do |trace|
            if elt = trace.format and trace.agent_type == agent_type
              log.elements << elt
            end
          end
        end
      end

      def make_traces
        group_by_uuid.map do |uuid, records|
          Trace.new(uuid).tap do |trace|
            trace.events = records.sort{|a, b| a["timestamp"] <=> b["timestamp"]}.map do |record|
              Event.new(record["state"], record["component"], record["timestamp"], record["transition"])
            end
          end
        end
      end
    end
  end
end
