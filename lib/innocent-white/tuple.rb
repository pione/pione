require 'innocent-white/innocent-white-object'

module InnocentWhite
  module Tuple
    TABLE = Hash.new

    class TupleData < InnocentWhiteObject

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

      def initialize(data={})
        @data = data.delete_if {|key,v| not(self.class.format.include?(key))}
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

      def to_s
        "#<#<TupleData:#{identifier}:#{uuid}> #{to_a.to_s}>"
      end

      def to_tuple_space_form
        to_a
      end
    end

    # Define a tuple format and create a class representing it.
    def self.define_format(format)
      TABLE[format.first] = TupleData.define(format)
    end

    # Return a class corresponding to a tuple identifier.
    def self.[](identifier)
      TABLE[identifier]
    end

    # Return a tuple data object converted from an array.
    def self.from_array(ary)
      return ary unless ary.kind_of?(Array)
      begin
        tuple = TABLE[ary.first]
        keys = tuple.format[1..-1]
        args = ary[1..-1]
        tuple.new(Hash[keys.zip(args))
      rescue ary end
    end

    #
    # define Tuples
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
