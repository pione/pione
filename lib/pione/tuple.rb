require 'pione/common'

module Pione
  module Tuple
    TABLE = Hash.new

    class FormatError < ArgumentError
    end

    # Type represents tuple's field data type which has or-relation.
    class Type
      def self.or(*args)
        new(*args)
      end

      def initialize(*args)
        @types = args
      end

      def ===(other)
        @types.find {|t| t === other}
      end
    end

    class TupleObject < PioneObject

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
        @format.each do |key, _|
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

      def initialize(*data)
        @data = {}
        return if data.empty?

        format = self.class.format
        format_keys = format.map{|key,_| key}
        format_table = Hash[*format[1..-1].select{|item| item.kind_of?(Array)}.flatten(1)]
        if data.first.kind_of?(Hash)
          _data = data.first
          _data.keys.each do |key|
            # key check
            raise FormatError.new(key) unless format_keys.include?(key)
            # type check
            if _data[key] && not(format_table[key].nil?)
              unless format_table[key] === _data[key]
                raise FormatError.new(_data[key])
              end
            end
          end
          @data = _data
        else
          raise FormatError.new(data) unless data.size == format.size - 1
          # type check
          data.each_with_index do |key, i|
            if format[i+1].kind_of?(Array)
              unless format[i+1][1] === data[i] or data[i].nil?
                raise FormatError.new(data[i])
              end
            end
          end
          @data = Hash[format_keys[1..-1].zip(data)]
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
        self.class.format[1..-1].map{|key, _| @data[key]}.unshift(identifier)
      end

      def to_json(*a)
        @data.merge({"tuple" => self.class.identifier}).to_json(*a)
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
      format.each {|name, _| raise FormatError.new(name) unless Symbol === name}
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

    # signal representation
    #   type : command string, currently "terminate" only
    define_format [:command, :type]

    # data representation
    #   domain : target domain
    #   name   : data name
    #   uri    : resource location
    #   time   : data created time
    define_format [:data,
      [:domain, String],
      [:name, Type.or(String, Model::DataExpr)],
      [:uri, String],
      [:time, Time]
    ]

    # rule application task with inputs, outpus and parameters
    #   rule_path : string     : rule location path
    #   inputs    : data list  : input data list
    #   params    : parameters : parameter list
    #   features  : feature    : request features
    #   domain    : string     : task domain
    define_format [:task,
      [:rule_path, String],
      [:inputs, Array],
      [:params, Model::Parameters],
      [:features, Model::Feature::Expr],
      [:domain, String],
      [:call_stack, Array]
    ]

    # working information
    #   domain : string : caller domain
    #   digest : string : rule handler digest
    define_format [:working,
      [:domain, String],
      [:digest, String]
    ]

    # task finished notifier
    #   domain  : string    : task domain
    #   status  : symbol    : status of the task processing
    #   outputs : data list : outputs
    #   digest  : string    : rule handler digest
    define_format [:finished,
      [:domain, String],
      [:status, Symbol],
      [:outputs, Array],
      [:digest, String]
    ]

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

    class Task
      # Returns digest string of the task.
      def digest
        "%s([%s],[%s])" % [
          rule_path,
          inputs.map{|i|
            i.kind_of?(Array) ? "[%s, ...]" % i[0].name : i.name
          }.join(","),
          params.data.map{|k,v| "%s:%s" % [k.name, v.textize]}.join(",")
        ]
      end
    end
  end
end
