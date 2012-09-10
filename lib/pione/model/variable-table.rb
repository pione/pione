require 'pione/common'

module Pione::Model

  # UnboundVariableError represents an unknown variable reference.
  class UnboundVariableError < StandardError
    attr_reader :variable

    def initialize(variable)
      @variable = variable
      msg = "Refferred unbound variable '%s' in the context."
      super(msg % [@variable.name])
    end
  end

  # VariableBindingError represents an error that you try to bind different value
  # to a variable.
  class VariableBindingError < StandardError
    attr_reader :variable
    attr_reader :new_value
    attr_reader :old_value

    def initialize(variable, new_value, old_value)
      @variable = variable
      @new_value = new_value
      @old_value = old_value
      args = [
        @new_value.textize,
        @variable.name,
        @old_value.textize,
        @variable.line,
        @variable.column
      ]
      message = <<MSG % args
Try to bind the value '%s' as variable %s, but already bound the value '%s'(line: %s, column: %s)
MSG
      super(message)
    end
  end

  # VariableTable represents variable table for rule and data finder.
  class VariableTable < PioneModelObject
    set_pione_model_type TypeVariableTable

    # Make an auto vairable table.
    def initialize(table={})
      @table = table.to_hash.dup
      super()
    end

    # Returns empty variable table
    def self.empty
      new
    end

    # Return the variable table as hash.
    def to_hash
      @table
    end

    # Returns the parameters form.
    def to_params
      Parameters.new(to_hash)
    end

    # Return true if the table is empty.
    def empty?
      @table.empty?
    end

    # Get the variable value.
    def get(var)
      raise ArgumentError.new(var) unless var.kind_of?(Variable)
      val = @table[var]
      if val.kind_of?(Variable)
        next_val = get(@table[var])
        return next_val.nil? ? val : next_val
      elsif val.kind_of?(PioneModelObject) and not(val.atomic?)
        return val.eval(self)
      else
        return val
      end
    end

    # Sets a new variable. This method raises an exception when the variable has
    # its value already.
    def set(variable, new_value)
      raise TypeError.new(variable) unless variable.kind_of?(Variable)
      raise TypeError.new(new_value) unless new_value.kind_of?(PioneModelObject)
      if old_value = @table[variable]
        unless old_value.kind_of?(UndefinedValue) or new_value == old_value
          raise VariableBindingError.new(variable, new_value, old_value)
        end
      end
      @table[variable] = new_value
    end

    # Sets a variable. This method overrides old variable value.
    def set!(variable, new_value)
      raise TypeError.new(variable) unless variable.kind_of?(Variable)
      raise TypeError.new(new_value) unless new_value.kind_of?(PioneModelObject)
      @table[variable] = new_value
    end

    # Expand variables in the string.
    def expand(str)
      variables = to_hash
      new_str = str.to_s.gsub(/\{(\$.+?)\}/) do
        expr = Transformer.new.apply(Parser.new.expr.parse($1))
        expr.eval(self).call_pione_method("as_string").to_ruby
        # var = Variable.new($1)
        # if variables.has_key?(var)
        #   variables[var].to_ruby
        # else
        #   raise UnboundVariableError.new(Variable.new($1))
        # end
      end
      new_str.gsub(/\<\?\s*(.+?)\s*\?\>/) do
        expr = Transformer.new.apply(Parser.new.expr.parse($1))
        expr.eval(self).call_pione_method("as_string").to_ruby
      end
    end

    # Returns key variables of the table.
    def variables
      @table.keys
    end

    # FIXME
    def self.check_include_variable(str)
      str = str.to_s
      return true if /\{\$(.+?)\}/.match(str)
      str.gsub(/\<\?\s*(.+?)\s*\?\>/) do
        expr = Transformer.new.apply(Parser.new.expr.parse($1))
        return true if expr.include_variable?
      end
      return false
    end

    def include_variable?
      # FIXME
      @table.values.any?{|val| val.include_variable?}
    end

    # Make input auto-variables
    # [+input_exprs+] input expressions
    # [+input_tuples+] input tuples
    def make_input_auto_variables(input_exprs, input_tuples)
      set(Variable.new("INPUT"), Variable.new("I"))
      input_exprs.each_with_index do |expr, index|
        make_io_auto_variables(:input, expr, input_tuples[index], index+1)
      end
    end

    # Make output auto-variables.
    # [+output_exprs+] output expressions
    # [+output_tuples+] output tuples
    def make_output_auto_variables(output_exprs, output_tuples)
      set(Variable.new("OUTPUT"), Variable.new("O"))
      output_exprs.each_with_index do |expr, index|
        make_io_auto_variables(:output, expr, output_tuples[index], index+1)
      end
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @table == other.to_hash
    end

    alias :eql? :==

    def hash
      @table.hash
    end


    private

    # Make input or output auto variables.
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
