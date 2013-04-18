module Pione
  module Log
    # UnknownProcessRecordType is raised when we find unknown process types.
    class UnknownProcessRecordType < StandardError
      # @param type [Symbol]
      #   type name
      def initialize(type)
        @type = type
      end

      # @api private
      def message
        'Unknown process type "%s"' % @type
      end
    end

    # ProcessRecord is a class that represents records of process log. Records
    # are in tuple spaces and handled by PIONE's logger agent.
    class ProcessRecord
      # known process record types and classes
      TYPE_TABLE = {}

      class << self
        # @return [String]
        #   record type
        attr_reader :type

        # @return [Array<Symbol>]
        #   field names
        attr_reader :fields

        # Build a new record from hash table.
        #
        # @param hash [Hash{Symbol=>String}]
        def build(hash)
          if klass = TYPE_TABLE[hash[:type].to_sym]
            klass.new(hash)
          else
            raise UnknownProcessRecordType.new(hash[:type])
          end
        end

        private

        # Set type of the record class.
        def set_type(name)
          @type = name
          ProcessRecord::TYPE_TABLE[name] = self
        end

        # Declare to append the named field into records.
        #
        # @param name [Symbol]
        #   field name of the record
        # @return [void]
        def field(name)
          unless (@fields ||= []).include?(name)
            @fields << name

            define_method(name) do
              instance_variable_get("@%s" % name)
            end

            define_method("%s=" % name) do |val|
              val = Time.parse(val) if name == :timestamp and val.kind_of?(String)
              instance_variable_set("@%s" % name, val)
            end
          end
        end

        # @api private
        def inherited(klass)
          klass.instance_variable_set(:@fields, @fields.clone)
        end
      end

      # @!attribute [rw]
      # @return [Time]
      #   record timestamp
      field :timestamp

      # @!attribute [rw]
      # @return [String]
      #   transition name
      field :transition

      forward! :class, :type, :fields

      # Create a new process log record.
      #
      # @param data [Hash{String => Object}]
      #   log content
      def initialize(data={})
        data.each {|key, val| send("%s=" % key, val) unless key == :type}
      end

      # Create a copy of the record and merge the data into it.
      #
      # @return [ProcessRecord]
      #   new merged record
      def merge(data)
        ProcessRecord.build(to_hash).tap do |record|
          data.each do |key, val|
            record.send("%s=" % key, val)
          end
        end
      end

      # Format as JSON string.
      #
      # @return [String]
      #   JSON string
      def format
        JSON.dump(to_hash)
      end

      # Convert record into a hash table.
      #
      # @return [Hash]
      #   hash table representation of the record
      def to_hash
        fields.inject({type: type}) do |table, name|
          table.tap do
            if val = send(name)
              val = val.iso8601(3) if name == :timestamp
              table[name] = val
            end
          end
        end
      end

      # @api private
      def to_json(*args)
        to_hash.to_json(*args)
      end
    end

    # CreateChildTaskWorkerProcessRecord represents the event that a task worker
    # creates the child task worker.
    class CreateChildTaskWorkerProcessRecord < ProcessRecord
      set_type :create_child_task_worker
      field :parent
      field :child
    end

    # PutDataProcessRecord represents data uploading to some location.
    class PutDataProcessRecord < ProcessRecord
      set_type :put_data
      field :agent_type
      field :agent_uuid
      field :location
      field :size
    end

    # AgentActivityProcessRecord represents agent acitivity about state transition.
    class AgentActivityProcessRecord < ProcessRecord
      set_type :agent_activity
      field :agent_type
      field :agent_uuid
      field :state
    end

    # AgentConnectionProcessRecord represents hello and bye message from agents.
    class AgentConnectionProcessRecord < ProcessRecord
      set_type :agent_connection
      field :agent_type
      field :agent_uuid
      field :message
    end

    # RuleProcessRecord represents lifecyles of rule process.
    class RuleProcessRecord < ProcessRecord
      set_type :rule_process
      field :name
      field :rule_type
      field :caller
    end

    # TaskProcessRecord represents lifecyle of task process.
    class TaskProcessRecord < ProcessRecord
      set_type :task_process
      field :name
      field :rule_name
      field :rule_type
      field :inputs
      field :parameters
    end
  end
end
