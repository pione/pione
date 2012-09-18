module Pione::Model

  # Message represents method caller for Pione model objects.
  # @example
  #   1.as_string()
  # @example
  #   '*.txt'.except('a*')
  class Message < PioneModelObject
    attr_reader :name
    attr_reader :receiver
    attr_reader :arguments

    # Creates a message.
    # @param [String] name
    #   message name
    # @param [PioneModelObject] receiver
    #   message receiver
    # @param [PioneModelObject] arguments
    #   message arguments
    def initialize(name, receiver, *arguments)
      @name = name
      @receiver = receiver
      @arguments = arguments
      super()
    end

    # Returns false because Message is a complex form.
    # @return [Boolean]
    #   false
    def atomic?
      false
    end

    # Returns PIONE model type.
    # @return [Symbol]
    #   PIONE model type
    def pione_model_type
      @receiver.pione_model_type.method_interface[@name.to_s].output
    end

    # Evaluates the application expression and returns application result.
    # @param [VariableTable] vtable variable table for the evaluation
    # @return [PioneModelObject]
    #   evaluation result
    def eval(vtable=VariableTable.new)
      receiver = @receiver.eval(vtable)
      arguments = @arguments.map{|arg| arg.eval(vtable)}
      receiver.call_pione_method(@name, *arguments)
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @name == other.name
      return false unless @receiver == other.receiver
      return false unless @arguments == other.arguments
      return true
    end

    # Returns true if receiver or arguments include variables.
    # @return [Boolean]
    #   true if receiver or arguments include variables
    def include_variable?
      @receiver.include_variable? or @arguments.any?{|arg| arg.include_variable?}
    end

    # @api private
    def textize
      "message(\"%s\",%s,[%s])" % [
        @name, @receiver.textize,@argument.textize
      ]
    end

    alias :eql? :"=="

    # @api private
    def hash
      @name.hash + @receiver.hash + @arguments.hash
    end
  end
end
