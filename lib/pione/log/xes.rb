module Pione
  module Log
    # XESExtension represents "extension" element of XES.
    class XESExtension
      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :prefix

      # @return [String]
      attr_reader :uri

      # Create a XES extension element.
      #
      # @param name [String]
      #   extension name
      # @param prefix [String]
      #   extension prefix
      # @param uri [String]
      #   extension definition URI
      def initialize(name, prefix, uri)
        @name = name
        @prefix = prefix
        @uri = uri
      end

      # Format as a XML element.
      def format
        REXML::Element.new("extension").tap do |ext|
          ext.attributes["name"] = @name
          ext.attributes["prefix"] = @prefix
          ext.attributes["uri"] = @uri
        end
      end
    end

    # "Concept" XES extension element
    XESEXT_CONCEPT = XESExtension.new("Concept", "concept", "http://www.xes-standard.org/concept.xesext")

    # "Identity" XES extension element
    XESEXT_IDENTITY = XESExtension.new("Identity", "identity", "http://www.xes-standard.org/identity.xesext")

    # "Time" XES extension element
    XESEXT_TIME = XESExtension.new("Time", "time", "http://www.xes-standard.org/time.xesext")

    # "Lifecycle" XES extension element
    XESEXT_LIFECYCLE = XESExtension.new("Lifecycle", "lifecycle", "http://www.xes-standard.org/lifecycle.xesext")

    # "Organizational" XES extension element
    XESEXT_ORGANIZATIONAL = XESExtension.new("Organizational", "org", "http://www.xes-standard.org/org.xesext")

    # XESClassifier represents "classifier" element of XES.
    class XESClassifier
      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :keys

      # Create a XES classifier element.
      #
      # @param name [String]
      #   classifier name
      # @param keys [String]
      #   classifier keys
      def initialize(name, keys)
        @name = name
        @keys = keys
      end

      # Format as a XML element.
      #
      # @return [REXML::Element]
      #   XML element
      def format
        REXML::Element.new("classifier").tap do |ext|
          ext.attributes["name"] = @name
          ext.attributes["keys"] = @keys
        end
      end
    end

    MXML_LEGACY_CLASSIFIER = XESClassifier.new("MXML Legacy Classifier", "concept:name lifecycle:transition")
    EVENT_NAME = XESClassifier.new("Event Name", "concept:name")
    RESOURCE = XESClassifier.new("Resource", "org:resource")

    # XESTrace represents "trace" element of XES.
    class XESTrace
      # @return [String]
      attr_reader :uuid

      # @return [Array<XESEvent>]
      attr_accessor :events

      # Create a XES trace.
      #
      # @param uuid [String]
      #   UUID
      # @param events [Array<XESEvent>]
      #   events that trace contains
      def initialize(uuid, events=[])
        @uuid = uuid
        @events = events
      end

      # Format as a XML element.
      #
      # @return [REXML::Element]
      #   XML element
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

      # Return agent type string.
      #
      # @return [String]
      #   agent type id
      def agent_type
        resource = @events.first.resource
      end
    end

    # XESEvent represents "event" element of XES.
    class XESEvent
      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :resource

      # @return [Time]
      attr_reader :timestamp

      # @return [String]
      attr_reader :transition

      # Create a XES event.
      #
      # @param name [String]
      #   concept:name
      # @param resource [String]
      #   org:resource
      # @param timestamp [Time]
      #   time:timestamp
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

      # Format as a XML element.
      #
      # @return [REXML::Element]
      #   XML element
      def format
        REXML::Element.new("event").tap do |event|
          event.add_element("string", {"key" => "concept:name", "value" => @name})
          event.add_element("string", {"key" => "org:resource", "value" => @resource})
          event.add_element("date", {"key" => "time:timestamp", "value" => @timestamp.iso8601(3)})
          event.add_element("string", {"key" => "lifecycle:transition", "value" => @transition})
        end
      end
    end

    # AgentXESFormatter is a log formatter for agent activities
    class AgentXESFormatter
      # Create a XES formatter for agent activities.
      #
      # @param log [LogFile]
      #   log file
      # @param agent_type [String]
      #   agent type string
      def initialize(log, agent_type)
        @log = log
        @agent_type = agent_type
      end

      # Format as a XML document.
      #
      # @return [REXML::Document]
      #   XML document
      def format
        REXML::Document.new.tap do |doc|
          doc.elements << make_root
          doc << REXML::XMLDecl.new
        end
      end

      private

      # Make root element.
      #
      # @return [REXML::Element]
      #   XML element
      def make_root
        REXML::Element.new("log").tap do |log|
          log.attributes["xes.version"] = "1.4"
          log.attributes["xes.features"] = ""
          log.attributes["openxes.version"] = "1.0RC7"
          log.attributes["xmlns"] = "http://www.xes-standard.org/"
          log.elements << XESEXT_CONCEPT.format
          log.elements << XESEXT_IDENTITY.format
          log.elements << XESEXT_TIME.format
          log.elements << XESEXT_LIFECYCLE.format
          log.elements << XESEXT_ORGANIZATIONAL.format
          log.elements << MXML_LEGACY_CLASSIFIER.format
          log.elements << EVENT_NAME.format
          log.elements << RESOURCE.format
          log.add_element("string", {"key" => "concept:name", "value" => "PIONE agent activity log"})
          make_traces.each do |trace|
            if elt = trace.format
              if @agent_type.nil? or trace.agent_type == @agent_type
                log.elements << elt
              end
            end
          end
        end
      end

      # Make trace objects.
      #
      # @return [Array<XESTrace>]
      def make_traces
        @log.group_by("uuid").map do |uuid, records|
          XESTrace.new(uuid).tap do |trace|
            records.sort{|a, b| a.timestamp <=> b.timestamp}.map do |record|
              trace.events << XESEvent.new(record["state"], record.component, record.timestamp, record["transition"])
            end
          end
        end
      end
    end
  end
end
