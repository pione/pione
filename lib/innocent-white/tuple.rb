require 'innocent-white/common'

module InnocentWhite
  module Tuple
    TABLE = Hash.new

    class FormatError < ArgumentError; end

    class TupleObject < InnocentWhiteObject

      # -- class --

      # Define a tuple class and return its class.
      def self.define(format)
        klass = Class.new(self) do
          set_format format
        end
        Tuple.const_set(klass.classname, klass)
        return klass
      end

      # Return class name of the tuple format.
      def self.classname
        identifier.to_s.capitalize.gsub(/_(.)/){ $1.upcase }
      end

      # Set tuple's format.
      def self.set_format(definition)
        @format = definition

        # create accessors
        @format.each do |key|
          define_method(key) do
            @data[key]
          end
          define_method("#{key}=") do |val|
            @data[key] = val
          end
        end
      end

      # Return tuple's format.
      def self.format
        @format
      end

      # Return the identifier.
      def self.identifier
        @format.first
      end

      # Return a respresentation for matching any tuples of same type.
      def self.any
        new
      end

      # -- instance --

      def initialize(*data)
        @data = {}
        return if data.empty?

        format = self.class.format
        if data.first.kind_of?(Hash)
          _data = data.first
          _data.keys.each do |key|
            raise FormatError.new(key) if not(format.include?(key))
          end
          @data = _data
        else
          raise FormatError.new(data) unless data.size == format.size - 1
          @data = Hash[format[1..-1].zip(data)]
        end
      end

      def ==(other)
        case other
        when TupleObject
          to_tuple_space_form == other.to_tuple_space_form
        else
          to_tuple_space_form == other.to_a
        end
      end

      alias :eql? :==

      def hash
        @data.hash
      end

      # Return the identifier.
      def identifier
        self.class.identifier
      end

      # Convert to string form.
      def to_s
        "#<#<#{self.class.name}> #{to_tuple_space_form.to_s}>"
      end

      # Convert to plain tuple form.
      def to_tuple_space_form
        self.class.format[1..-1].map{|key| @data[key]}.unshift(identifier)
      end

      def to_log_value
        @data.merge({"tuple" => self.class.identifier}).to_json
      end

      # Return the value of the specified position.
      def value(i = 0)
        @data[i]
      end

      def writable?
        self.class.format.map do |symbol|
          @data.has_key?(symbol)
        end.unique == [true]
      end
    end

    # Define a tuple format and create a class representing it.
    def self.define_format(format)
      identifier = format.first

      # check arguments
      # format is a list of symbols
      format.each {|f| raise FormatError.new(f) unless Symbol === f}
      # fobid to define same identifier and different format
      if TABLE.has_key?(identifier)
        if not(TABLE[identifier].format == format)
          raise FormatError.new(identifier)
        else
          return TABLE[identifier]
        end
      end

      # make a class and set it in a table
      klass = TupleObject.define(format)
      TABLE[identifier] = klass
    end

    # Delete a tuple format definition.
    def self.delete_format(identifier)
      if TABLE.has_key?(identifier)
        name = TABLE[identifier].name.split('::').last
        TABLE.delete(identifier)
        remove_const(name)
      end
    end

    # Return a class corresponding to a tuple identifier.
    def self.[](identifier)
      TABLE[identifier]
    end

    # Return a tuple data object converted from an array.
    def self.from_array(ary)
      raise FormatError.new(ary) unless ary.size > 0
      raise FormatError.new(ary) unless ary.kind_of?(Enumerable)
      _ary = ary.to_a
      identifier = _ary.first
      raise FormatError.new(identifier) unless TABLE.has_key?(identifier)
      args = _ary[1..-1]
      TABLE[identifier].new(*args)
    end

    # -- define tuples --

    # data representation
    #   domain : target domain
    #   name   : data name
    #   uri    : resource location
    define_format [:data, :domain, :name, :uri]

    # rule application task with inputs, outpus and parameters
    #   rule_path : rule location path
    #   inputs    : input data list
    #   params    : parameter list
    define_format [:task, :rule_path, :inputs, :params]

    # working information
    #   domain  : caller domain
    #   task_id : task id
    define_format [:working, :domain, :task_id]

    # task finished notifier
    #   domain  : uuid of the task
    #   status  : status of the task processing
    #   outputs : outputs
    define_format [:finished, :domain, :status, :outputs]

    # agent connection notifier in the tuple space server
    #   uuid       : uuid of the agent
    #   agent_type : agent type
    define_format [:agent, :uuid, :agent_type]

    # bye message from agent
    #   uuid : uuid of the agent
    define_format [:bye, :uuid, :agent_type]

    # parent_agent: agent tree information
    define_format [:parent_agent, :parent_id, :child_id]

    # log a message
    #   obj : Log's instance
    define_format [:log, :message]

    # number of task worker for tuple space server
    #   number : resource number of task workers.
    define_format [:task_worker_resource, :number]

    # request rule for provider
    #   rule_path : rule location path
    define_format [:request_rule, :rule_path]

    # represent rule content
    #   rule_path : rule location path
    #   content   : rule content
    define_format [:rule, :rule_path, :content, :status]

    # exception notifier from agents
    #   uuid  : uuid of the agent who happened the exception
    #   value : exception object
    define_format [:exception, :uuid, :agent_type, :value]

    # location information of resource
    #   uri : base uri of all resources on the server
    define_format [:base_uri, :uri]

    # process information
    #   name : process name
    #   pid  : process id
    define_format [:process_info, :name, :process_id]

    # sync target information
    #   src  : sync source domain
    #   dest : sync destinaiton domain
    #   name : data name
    define_format [:sync_target, :src, :dest, :name]

  end
end
