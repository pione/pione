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
        msg = "Format error found in %s tuple: %s" % [@identifier, @invalid_data.inspect]
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
    class Type < PioneObject
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

    module TupleDefinition
      # Defines a tuple format and create a class representing it.
      # @return [void]
      def define_format(format)
        raise ScriptError if @format
        @format = format

        identifier = format.first
        set_attr_accessors

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
        TABLE[identifier] = self
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

      # Return location position of the format.
      #
      # @return [Integer or nil]
      #   position number of location field, or nil
      # @api private
      def location_position
        position_of(:location)
      end

      private

      # Sets the tuple format and creates accessor methods.
      # @param [Array] definition
      #   tuple format
      # @return [void]
      def set_attr_accessors
        @format.each do |key, _|
          define_method(key) {@data[key]}
          define_method("%s=" % key) {|val| @data[key] = val}
        end
      end

      # @api private
      def position_of(name)
        @format.each_with_index do |key, i|
          key = key.kind_of?(Array) ? key.first : key
          return i if key == name
        end
        return nil
      end
    end

    # TupleObject is a superclass for all tuple classes.
    class BasicTuple < PioneObject
      def self.inherited(klass)
        klass.extend TupleDefinition
      end

      attr_accessor :timestamp

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
            raise FormatError.new(data, format.first)
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
        return false unless self.class == other.class
        to_tuple_space_form == other.to_tuple_space_form
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

    # parent_agent: agent tree information
    # define_format [:parent_agent, :parent_id, :child_id]
  end
end
