module Pione::Model
  # UnboundVariableError represents an unknown variable reference.
  class UnboundVariableError < StandardError
    attr_reader :variable

    # Creates an error.
    # @param [Variable] variable
    #   unbound variable
    def initialize(variable)
      @variable = variable
    end

    # @api private
    def message
      "Refferred unbound variable '%s' in the context." % @variable.name
    end
  end

  # VariableBindingError represents an error that you try to bind different value
  # to a variable.
  class VariableBindingError < StandardError
    attr_reader :variable
    attr_reader :new_value
    attr_reader :old_value

    # Creates an error.
    # @param [Variable] variable
    #   double bound variable
    # @param [PioneModelObject] new_value
    #   new value
    # @param [PioneModelObject] old_value
    #   old value
    def initialize(variable, new_value, old_value)
      @variable = variable
      @new_value = new_value
      @old_value = old_value
    end

    # @api private
    def message
      args = [
        @new_value.textize,
        @variable.name,
        @old_value.textize,
        @variable.line,
        @variable.column
      ]
      message = [
        "Try to bind the value '%s' as variable %s, ",
        "but already bound the value '%s'",
        "(line: %s, column: %s)"
      ] % args
    end
  end

  # VariableTable represents variable tables for rule context.
  class VariableTable < PioneModelObject
    set_pione_model_type TypeVariableTable

    # Returns empty variable table.
    # @return [VariableTable]
    #   empty variable table
    def self.empty
      new
    end

    # Creates a vairable table.
    # @param [Hash{Variable => PioneModelObject}] table
    #   initial values for the variable table
    def initialize(table={})
      @table = table.to_hash.dup
      super()
    end

    # Returns the variable table as hash.
    # @return [Hash{Variable => PioneModelObject}]
    #   hash form of the variable table
    def to_hash
      @table
    end

    # Returns the parameters form.
    # @return [Parameters]
    #   parameters form of the variable table
    def to_params
      Parameters.new(to_hash)
    end

    # Returns true if the table is empty.
    # @return [Boolean]
    #   true if the table is empty
    def empty?
      @table.empty?
    end

    # Gets the variable value and evaluates the value if the value is not
    # atomic.
    # @param [Variable] var
    #   table key to get the value
    # @return [PioneModelObject]
    #   the value
    def get(var)
      check_argument_type(var, Variable)
      val = @table[var]
      case val
      when Variable
        next_val = get(val)
        return next_val.nil? ? val : next_val
      when PioneModelObject
        return not(val.atomic?) ? val.eval(self) : val
      end
      return val
    end

    # Sets a new variable. This method raises an exception when the variable has
    # its value already.
    # @param [Variable] variable
    #   table key
    # @param [PioneModelObject] new_value
    #   new value
    # @return [VariableTable]
    #   new variable table
    def set(variable, new_value)
      check_argument_type(variable, Variable)
      check_argument_type(new_value, PioneModelObject)
      if old_value = @table[variable]
        unless old_value.kind_of?(UndefinedValue) or new_value == old_value
          raise VariableBindingError.new(variable, new_value, old_value)
        end
      end
      @table[variable] = new_value
    end

    # Sets a variable. This method overrides old variable value.
    # @param [Variable] variable
    #   table key
    # @param [PioneModelObject] new_value
    #   new value
    # @return [void]
    def set!(variable, new_value)
      check_argument_type(variable, Variable)
      check_argument_type(new_value, PioneModelObject)
      @table[variable] = new_value
    end

    # Expands variables in the string.
    # @param [String] str
    #   string
    # @return [String]
    #   expanded string
    def expand(str)
      variables = to_hash
      new_str = str.to_s.gsub(/\{(\$.+?)\}/) do
        expr = Transformer.new.apply(Parser.new.expr.parse($1))
        expr.eval(self).call_pione_method("as_string").to_ruby
      end
      new_str.gsub(/\<\?\s*(.+?)\s*\?\>/) do
        expr = Transformer.new.apply(Parser.new.expr.parse($1))
        expr.eval(self).call_pione_method("as_string").to_ruby
      end
    end

    # Returns key variables of the table.
    # @return [Array<Variable>]
    #   variable as table keys
    def variables
      @table.keys
    end

    # FIXME
    # Returns true if the string includes variables.
    # @param [String] str
    #   target string
    # @return [Boolean]
    #   true if the string includes variables
    def self.check_include_variable(str)
      str = str.to_s
      return true if /\{\$(.+?)\}/.match(str)
      str.gsub(/\<\?\s*(.+?)\s*\?\>/) do
        expr = Transformer.new.apply(Parser.new.expr.parse($1))
        return true if expr.include_variable?
      end
      return false
    end

    # Returns true if table's values include variables.
    # @return [Boolean]
    #   true if table's values include variables
    def include_variable?
      # FIXME
      @table.values.any?{|val| val.include_variable?}
    end

    # Makes input auto-variables.
    # @param [Array<DataExpr>] input_exprs
    #   input expressions
    # @param [Array<Expr>] input_tuples
    #   input tuples
    # @return [void]
    def make_input_auto_variables(input_exprs, input_tuples)
      set(Variable.new("INPUT"), Variable.new("I"))
      input_exprs.each_with_index do |expr, index|
        make_io_auto_variables(:input, expr, input_tuples[index], index+1)
      end
    end

    # Makes output auto-variables.
    # @param [Array<DataExpr>] output_exprs
    #   output expressions
    # @param [Array<DataExpr>] output_tuples
    #   output tuples
    # @return [void]
    def make_output_auto_variables(output_exprs, output_tuples)
      set(Variable.new("OUTPUT"), Variable.new("O"))
      output_exprs.each_with_index do |expr, index|
        make_io_auto_variables(:output, expr, output_tuples[index], index+1)
      end
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      @table == other.to_hash
    end

    alias :eql? :"=="

    # @api private
    def hash
      @table.hash
    end

    private

    # Make input or output auto variables.
    # @api private
    def make_io_auto_variables(type, expr, data, index)
      expr = expr.eval(self)
      prefix = (type == :input ? "I" : "O")
      case expr.modifier
      when :all
        make_io_auto_variables_by_all(type, prefix, expr, data)
      when :each
        make_io_auto_variables_by_each(prefix, expr, data, index)
      end
    end

    # Make input or output auto variables for 'exist' modified data name
    # expression.
    # @api private
    def make_io_auto_variables_by_each(prefix, expr, tuple, index)
      return if tuple.nil?
      # variable
      var = Variable.new(prefix)
      # matched data
      md = expr.match(tuple.name).to_a

      # setup rule-io list
      list = get(var)
      list = RuleIOList.new unless list
      elt = RuleIOElement.new(PioneString.new(tuple.name))
      elt.uri = PioneString.new(tuple.uri)
      elt.match = PioneList.new(*md.map{|d| PioneString.new(d)})

      # update the list
      set!(var, list.add(elt))

      # set special variable if index equals 1
      if prefix == 'I' && index == 1
        set(Variable.new("*"), PioneString.new(md[1]))
      end
    end

    # Make input or output auto variables for 'all' modified data name
    # expression.
    # @api private
    def make_io_auto_variables_by_all(type, prefix, expr, tuples)
      # FIXME: output
      return if type == :output

      # variable
      var = Variable.new(prefix)

      # setup rule-io list
      list = get(var)
      list = RuleIOList.new unless list
      io_list = RuleIOList.new()

      # convert each tuples
      tuples.each do |tuple, i|
        elt = RuleIOElement.new(PioneString.new(tuple.name))
        elt.uri = PioneString.new(tuple.uri)
        elt.match = PioneList.new(
          *expr.match(tuple.name).to_a.map{|m| PioneString.new(m)}
        )
        io_list.add!(elt)
      end

      # update
      set!(var, list.add(io_list))
    end

    #
    # pione methods
    #

    define_pione_method("get", [TypeString], TypeAny) do |name|
      get(Variable.new(name.value))
    end

    define_pione_method("keys", [], TypeList.new(TypeString)) do
      PioneList.new(@table.keys.map{|var| PioneString.new(var.name)})
    end
  end
end
