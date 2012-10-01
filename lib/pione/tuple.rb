module Pione
  module Tuple
    # tuple type table
    # @api private
    TABLE = Hash.new

    # FormatError is raised when tuple format is invalid.
    class FormatError < StandardError
      # Creates an error.
      # @param [Array<Object>] invalid_data
      #   invalid data
      # @param [Symbol] identifier
      #   tuple identifier
      def initialize(invalid_data, identifier=nil)
        @invalid_data = invalid_data
        @identifier = identifier
      end

      # Returns a message of this error.
      # @return [String]
      #   message string with invalid data and tuple identifier
      # @api private
      def message
        msg = @invalid_data.inspect
        msg += " in %s" % @identifier if @identifier
        return msg
      end
    end

    # Type represents tuple's field data type. Type has simple and complex form,
    # the latter is consisted by types or-relation. The method +===+ is used by
    # matching field data and type.
    # @example
    #   # create simple type
    #   simple_type = Type.new(String)
    #   simple_type === "abc" #=> true
    #   # create complex type
    #   complex_type = Type.new(String, Symbol)
    #   complex_type === "abc" #=> true
    #   complex_type === :abc  #=> true
    class Type
      class << self
        alias :or :new
      end

      # Creates a tuple field type.
      # @param [Array<Object>] types
      #   tuple field types
      def initialize(*types)
        raise ArgumentError.new(types) unless types.size > 0
        @types = types
      end

      # Returns true if the type is simple.
      # @return [Boolean]
      #   true if the type is simple, or false
      def simple?
        @types.size == 1
      end

      # Returns true if the type is complex.
      # @return [Boolean]
      #   true if the type is complex, or false
      def complex?
        not(simple?)
      end

      # @api private
      def ===(other)
        @types.find {|t| t === other}
      end
    end

    # TupleObject is a superclass for all tuple classes.
    class TupleObject < PioneObject
      class << self
        # Defines a new tuple class and returns it.
        # @param [Array] format
        #   tuple format
        # @return [TupleObject]
        #   new tuple object class which has the format
        def define(format)
          klass = Class.new(self) {set_format format}
          Tuple.const_set(klass.classname, klass)
          return klass
        end

        # Returns the class name from the tuple format.
        # @return [String]
        #   class name string
        def classname
          identifier.to_s.capitalize.gsub(/_(.)/){ $1.upcase }
        end

        # Sets the tuple format and creates accessor methods.
        # @param [Array] definition
        #   tuple format
        # @return [void]
        def set_format(definition)
          @format = definition

          # create accessors
          @format.each do |key, _|
            define_method(key) {@data[key]}
            define_method("%s=" % key) {|val| @data[key] = val}
          end
        end

        # Returns tuple's format.
        # @return [Array]
        #   tuple's format
        def format
          @format
        end

        # Returns the identifier.
        # @return [Symbol]
        #   identifier of the tuple
        def identifier
          @format.first
        end

        # Returns a respresentation for matching any tuples of same type.
        # @return [TupleObject]
        #   a query tuple that matches any tuples has the identifier
        def any
          new
        end

        # Returns domain position of the format.
        # @return [Integer, nil]
        #   position number of domain field, or nil
        # @api private
        def domain_position
          position_of(:domain)
        end

        # Returns uri position of the format.
        # @return [Integer, nil]
        #   position number of URI field, or nil
        # @api private
        def uri_position
          position_of(:uri)
        end

        private

        # @api private
        def position_of(name)
          @format.each_with_index do |key, i|
            key = key.kind_of?(Array) ? key.first : key
            return i if key == name
          end
          return nil
        end
      end

      # Creates new tuple object.
      # @param [Hash] data
      #   tuple data
      def initialize(*data)
        @data = {}
        return if data.empty?

        format = self.class.format
        format_keys = format.map{|key,_| key}
        format_table = Hash[*format[1..-1].select{|item|
            item.kind_of?(Array)
          }.flatten(1)]
        if data.first.kind_of?(Hash)
          _data = data.first
          _data.keys.each do |key|
            # key check
            unless format_keys.include?(key)
              raise FormatError.new(key, format.first)
            end
            # type check
            if _data[key] && not(format_table[key].nil?)
              unless format_table[key] === _data[key]
                raise FormatError.new(_data[key], format.first)
              end
            end
          end
          @data = _data
        else
          # length check
          unless data.size == format.size - 1
            raise FormatError.new(data, format.identifier)
          end
          # type check
          data.each_with_index do |key, i|
            if format[i+1].kind_of?(Array)
              # type specified
              unless format[i+1][1] === data[i] or data[i].nil?
                raise FormatError.new(data[i], format.first)
              end
            end
          end
          @data = Hash[format_keys[1..-1].zip(data)]
        end
      end

      # @api private
      def ==(other)
        case other
        when TupleObject
          to_tuple_space_form == other.to_tuple_space_form
        else
          to_tuple_space_form == other.to_a
        end
      end

      alias :eql? :"=="

      # @api private
      def hash
        @data.hash
      end

      # Returns the identifier.
      # @return [Symbol]
      #   tuple identifier
      def identifier
        self.class.identifier
      end

      # Converts the tuple to string form.
      # @api private
      def to_s
        "#<#<#{self.class.name}> #{to_tuple_space_form.to_s}>"
      end

      # Convert to plain tuple form.
      # @return [Array<Object>]
      #   tuple data array for Rinda's tuple space
      def to_tuple_space_form
        self.class.format[1..-1].map{|key, _| @data[key]}.unshift(identifier)
      end

      # Converts the tuple to json form.
      # @return [String]
      #   json form of the tuple
      def to_json(*a)
        @data.merge({"tuple" => self.class.identifier}).to_json(*a)
      end

      # Returns the value of the specified position.
      # @param [Integer] i
      #   field position to get
      # @return
      #   the value
      def value(i = 0)
        @data[i]
      end

      # Returns true if the field writable.
      # @return [Boolean]
      def writable?
        self.class.format.map do |symbol|
          @data.has_key?(symbol)
        end.unique == [true]
      end
    end

    class << self
      # Defines a tuple format and create a class representing it.
      # @return [void]
      def define_format(format)
        identifier = format.first

        # check arguments: format is a list of symbols
        format.each do |name, _|
          unless Symbol === name
            raise FormatError.new(name, identifier)
          end
        end

        # forbid to define same identifier and different format
        if TABLE.has_key?(identifier)
          if not(TABLE[identifier].format == format)
            raise FormatError.new(format, identifier)
          else
            return TABLE[identifier]
          end
        end

        # make a class and set it in a table
        klass = TupleObject.define(format)
        TABLE[identifier] = klass
      end

      # Deletes a tuple format definition.
      # @return [void]
      def delete_format(identifier)
        if TABLE.has_key?(identifier)
          name = TABLE[identifier].name.split('::').last
          TABLE.delete(identifier)
          remove_const(name)
        end
      end

      # Returns a tuple class corresponding to a tuple identifier.
      # @return [Class]
      #   tuple class
      def [](identifier)
        TABLE[identifier]
      end

      # Returns identifiers.
      # @return [Array<Symbol>]
      #   all tuple identifiers in PIONE system.
      def identifiers
        TABLE.keys
      end

      # Return a tuple data object converted from an array.
      # @return [TupleObject]
      #   tuple object
      def from_array(ary)
        raise FormatError.new(ary) unless ary.size > 0
        raise FormatError.new(ary) unless ary.kind_of?(Enumerable)
        _ary = ary.to_a
        identifier = _ary.first
        raise FormatError.new(identifier) unless TABLE.has_key?(identifier)
        args = _ary[1..-1]
        TABLE[identifier].new(*args)
      end
    end

    #
    # define tuples
    #

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
    #   rule_path : String
    #     rule location path
    #   inputs : Array<DataExpr, Array<DataExpr>>
    #     input data list
    #   params : Parameters
    #     parameter list
    #   features : FeatureExpr
    #     request features
    #   domain : String
    #     task domain
    #   call_stack : Array<String>
    #     call stack(domain list)
    define_format [:task,
      [:rule_path, String],
      [:inputs, Array],
      [:params, Model::Parameters],
      [:features, Model::Feature::Expr],
      [:domain, String],
      [:call_stack, Array]
    ]

    # working information
    #   domain : String
    #     caller domain
    #   digest : String
    #     rule handler digest
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

    # resource shift information
    #   old_uri : String : old uri
    #   new_uri : String : new uri
    define_format [:shift,
      [:old_uri, String],
      [:new_uri, String]
    ]

    define_format [:dry_run, :availability]

    # Task is tuple class for representing job of workers.
    class Task
      # Returns the digest string of the task.
      # @return [String]
      #   task digest string
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
