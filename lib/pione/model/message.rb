module Pione::Model
  # Message represents method callers for PIONE model objects.
  # @example
  #   1.as_string()
  # @example
  #   '*.txt'.except('a*')
  class Message < BasicModel
    attr_reader :name
    attr_reader :receiver
    attr_reader :arguments

    # Creates a message.
    # @param [String] name
    #   message name
    # @param [BasicModel] receiver
    #   message receiver
    # @param [BasicModel] arguments
    #   message arguments
    def initialize(name, receiver, *arguments)
      @name = name
      @receiver = receiver.to_pione
      @arguments = arguments.map{|arg| arg.to_pione}
      super()
    end

    # Returns false because Message is a complex form.
    # @return [Boolean]
    #   false
    def atomic?
      false
    end

    # Returns PIONE model type of the message result according to type
    # interface.
    # @return [Symbol]
    #   PIONE model type
    def pione_model_type
      @receiver.pione_model_type.method_interface[@name.to_s].output
    end

    # Evaluates the application expression and returns application result.
    # @param [VariableTable] vtable variable table for the evaluation
    # @return [BasicModel]
    #   evaluation result
    def eval(vtable)
      receiver = @receiver.eval(vtable)
      arguments = @arguments.map{|arg| arg.eval(vtable)}
      receiver.call_pione_method(@name, *arguments)
    end

    # Returns true if the receiver or arguments include variables.
    # @return [Boolean]
    #   true if the receiver or arguments include variables
    def include_variable?
      @receiver.include_variable? or @arguments.any?{|arg| arg.include_variable?}
    end

    # @api private
    def textize
      args = [@name, @receiver.textize, @arguments.textize]
      "message(\"%s\",%s,[%s])" % args
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @name == other.name
      return false unless @receiver == other.receiver
      return false unless @arguments == other.arguments
      return true
    end

    alias :eql? :"=="

    # @api private
    def hash
      @name.hash + @receiver.hash + @arguments.hash
    end
  end
end
