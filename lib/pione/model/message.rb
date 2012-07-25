module Pione::Model

  # Message represents method caller for Pione model objects.
  # For exmaple,
  #   1.as_string()
  #   '*.txt'.except('a*')
  class Message < PioneModelObject
    attr_reader :name
    attr_reader :receiver
    attr_reader :arguments

    # @param [String] name message name
    # @param [PioneModelObject] receiver message receiver
    # @param [PioneModelObject] arguments message arguments
    def initialize(name, receiver, *arguments)
      @name = name
      @receiver = receiver
      @arguments = arguments
    end

    # Returns false because Message is a complex form.
    def atomic?
      false
    end

    def pione_model_type
      @receiver.pione_model_type.method_interface[@name.to_s].output
    end

    # Evaluates the application expression and returns application result.
    # @param [VariableTable] vtable variable table for the evaluation
    def eval(vtable=VariableTable.new)
      receiver = @receiver.eval(vtable)
      arguments = @arguments.map{|arg| arg.eval(vtable)}
      receiver.call_pione_method(@name, *arguments)
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @name == other.name
      return false unless @receiver == other.receiver
      return false unless @arguments == other.arguments
      return true
    end

    def include_variable?
      @receiver.include_variable? or @arguments.any?{|arg| arg.include_variable?}
    end

    alias :eql? :==

    def hash
      @name.hash + @receiver.hash + @arguments.hash
    end
  end
end
