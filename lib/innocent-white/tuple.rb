require 'innocent-white/innocent-white-object'

module InnocentWhite
  module Tuple
    TABLE = Hash.new

    class TupleObject < InnocentWhiteObject

      # -- class methods --

      # Define a tuple data and return its class.
      def self.define(format)
        Class.new(self) do
          set_format format
        end
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

      # -- instance methods --

      def initialize(*data)
        @data = {}
        return if data.empty?

        format = self.class.format
        if data.first.kind_of?(Hash)
          _data = data.first
          @data = _data.delete_if {|key,v| not(format.include?(key))}
        else
          raise ArgumentError.new(data) unless data.size == format.size - 1
          @data = Hash[format[1..-1].zip(data)]
        end
      end

      def ==(other)
        to_a.eql?(other.to_a)
      end

      alias :eql? :==

      def hash
        @data.hash
      end

      # Return the identifier.
      def identifier
        self.class.identifier
      end

      # Convert to plain tuple form.
      def to_a
        self.class.format[1..-1].map{|key| @data[key]}.unshift(identifier)
      end

      # Convert to string form.
      def to_s
        "#<#<#{self.class.name}> #{to_a.to_s}>"
      end

      # Convert to plain tuple form.
      def to_tuple_space_form
        to_a
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
      format.each {|f| raise ArgumentError.new(f) unless Symbol === f}
      # fobid to define same identifier and different format
      if TABLE.has_key?(identifier)
        if not(TABLE[identifier].format == format)
          raise ArgumentError.new(identifier)
        else
          return TABLE[identifier]
        end
      end

      # make a class and set it in a table
      klass = TupleObject.define(format)
      const_set(identifier.capitalize, klass)
      TABLE[identifier] = klass
    end

    # Return a class corresponding to a tuple identifier.
    def self.[](identifier)
      TABLE[identifier]
    end

    # Return a tuple data object converted from an array.
    def self.from_array(ary)
      raise ArgumentError.new(ary) unless ary.kind_of?(Enumerable)
      _ary = ary.to_a
      identifier = _ary.first
      args = _ary[1..-1]
      TABLE[identifier].new(*args)
    end

    #
    # define tuples
    #
    define_format [:data, :data_type, :name, :path, :raw, :time]
    define_format [:task, :name, :inputs, :outputs, :params, :uuid]
    define_format [:finished, :uuid, :status]
    define_format [:agent, :agent_type, :uuid]
    define_format [:parent_agent, :parent_id, :child_id]
    define_format [:log, :level, :message]
    define_format [:task_worker_resource, :number]
    define_format [:request_module, :path]
    define_format [:module, :path, :content, :status]
    define_format [:bye, :agent_type, :uuid]
  end
end
