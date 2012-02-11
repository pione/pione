module InnocentWhite
  module Tuple
    TABLE = Hash.new

    class TupleData

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

      alias :plain :to_a
    end

    # Define a tuple format and create a class representing it.
    def self.define_format(format)
      TABLE[format.first] = TupleData.define(format)
    end

    # Return a class corresponding to a tuple identifier.
    def self.[](identifier)
      TABLE[identifier]
    end

    #
    # define Tuples
    #
    define_format [:data, :name, :path, :time]
    define_format [:task, :name, :inputs, :outputs, :params, :task_id]
    define_format [:agent, :agent_type, :agent_id]
    define_format [:parent_agent, :parent_id, :child_id]
    define_format [:log, :level, :message]
    define_format [:task_worker_resource, :number]
  end
end

class Array
  def to_tuple
    identifier = self.first
    arguments = self[1..-1]
    tuple = InnocentWhite::Tuple[identifier]
    data = {}
    (tuple.format.size-1).times do |i|
      data[tuple.format[i+1]] = self[i+1]
    end
    tuple.new(data)
  end
end
