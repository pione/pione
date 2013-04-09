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

    # known XES extension elements
    XES_EXTENSION = {
      :concept => XESExtension.new("Concept", "concept", "http://www.xes-standard.org/concept.xesext"),
      :identity => XESExtension.new("Identity", "identity", "http://www.xes-standard.org/identity.xesext"),
      :time => XESExtension.new("Time", "time", "http://www.xes-standard.org/time.xesext"),
      :lifecycle => XESExtension.new("Lifecycle", "lifecycle", "http://www.xes-standard.org/lifecycle.xesext"),
      :organizational => XESExtension.new("Organizational", "org", "http://www.xes-standard.org/org.xesext")
    }

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

    # known XES classifier elements
    XES_CLASSIFIER = {
      :mxml_legacy_classifier => XESClassifier.new("MXML Legacy Classifier", "concept:name lifecycle:transition"),
      :event_name => XESClassifier.new("Event Name", "concept:name"),
      :resource => XESClassifier.new("Resource", "org:resource")
    }

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
      def initialize(uuid=nil, events=[])
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
            trace.add_element("id", {"key" => "identity:id", "value" => @uuid}) if @uuid
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

      # Return true if the element is valid event element.
      #
      # @return [Boolean]
      #   true if the element is valid event element
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

    class XESFormatter
      class << self
        attr_reader :log_title

        # Set log titile as +concept:name+ attribute in log element.
        #
        # @param log_title [String]
        #   log title
        # @return [void]
        def set_log_title(log_title)
          @log_title = log_title
        end
      end

      forward :class, :log_title

      # Create a XES formatter.
      #
      # @param log_file [LogFile]
      #   PIONE log file
      def initialize(process_log)
        @process_log = process_log.select {|record| target?(record)}
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

      # Return true if the record is target in this formatter.
      #
      # @param record [Record]
      #   true if the record is target in this formatter
      def target?(record)
        raise NotImplementedError
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
          log.elements << XES_EXTENSION[:concept].format
          log.elements << XES_EXTENSION[:identity].format
          log.elements << XES_EXTENSION[:time].format
          log.elements << XES_EXTENSION[:lifecycle].format
          log.elements << XES_EXTENSION[:organizational].format
          log.elements << XES_CLASSIFIER[:mxml_legacy_classifier].format
          log.elements << XES_CLASSIFIER[:event_name].format
          log.elements << XES_CLASSIFIER[:resource].format
          log.add_element("string", {"key" => "concept:name", "value" => log_title})
          make_traces.each do |trace|
            log.elements << trace.format
          end
        end
      end
    end

    # AgentXESFormatter is a log formatter for agent activities
    class AgentXESFormatter < XESFormatter
      set_log_title "PIONE agent activity log"

      # Create a XES formatter for agent activities.
      #
      # @param process_log [LogFile]
      #   PIONE process log
      # @param agent_type [String]
      #   agent type string
      def initialize(process_log, agent_type)
        super(process_log)
        @agent_type = agent_type
      end

      def target?(record)
        record.component == @agent_type
      end

      # Make trace objects.
      #
      # @return [Array<XESTrace>]
      def make_traces
        @process_log.group_by("uuid").map do |uuid, records|
          XESTrace.new(uuid).tap do |trace|
            records.sort{|a, b| a.timestamp <=> b.timestamp}.map do |record|
              trace.events << XESEvent.new(record["state"], record.component, record.timestamp, record["transition"])
            end
          end
        end
      end
    end

    class RuleProcessXESFormatter < XESFormatter
      set_log_title "PIONE rule process log"

      def target?(record)
        record.component == "rule-handler"
      end

      def make_traces
        trace = XESTrace.new.tap do |trace|
          @process_log.map do |record|
            trace.events << XESEvent.new(record["name"], "pione", record.timestamp, record["transition"])
          end
        end
        return [trace]
      end
    end
  end
end
