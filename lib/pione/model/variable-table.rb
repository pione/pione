require 'pione/common'

module Pione::Model

  class UnboundVariableError < StandardError
    def initialize(variable)
      @variable = variable
    end
  end

  # UnknownVariableError represents an unknown variable reference.
  class UnknownVariableError < StandardError
    attr_reader :name

    def initialize(name)
      @name = name
      super("Unknown variable name '#{name}' in the context.")
    end
  end

  # VariableBindingError represents a error that you try to bind different value
  # to a variable.
  class VariableBindingError < StandardError
    attr_reader :name
    attr_reader :value
    attr_reader :old

    def initialize(name, value, old)
      @name = name
      @value = value
      @old = old
      message =
        "Try to bind the value '#{value}' as variable '#{name}'," +
        "but already bound the value '#{old}'"
      super(message)
    end
  end

  # VariableTable represents variable table for rule and data finder.
  class VariableTable < PioneModelObject
    # Make an auto vairable table.
    def initialize(table={})
      @table = table.to_hash.dup
    end

    # Return the variable table as hash.
    def to_hash
      @table
    end

    # Get the variable value.
    def get(var)
      raise ArgumentError.new(var) unless var.kind_of?(Variable)
      @table[var]
    end

    # Set a new variable.
    def set(variable, val=nil)
      raise ArgumentError.new(variable) unless variable.kind_of?(Variable)
      raise ArgumentError.new(val) unless val.kind_of?(PioneModelObject)
      if old = @table[variable] and not(val == old)
        raise VariableBindingError.new(variable, val, old)
      end
      @table[variable] = val
    end

    # Expand variables in the string.
    def expand(str)
      variables = to_hash
      str.gsub(/\{\$(.+?)\}/) do
        var = Variable.new($1)
        if variables.has_key?(var)
          variables[var].to_ruby
        else
          raise UnknownVariableError.new($1)
        end
      end
    end

    # Make input auto-variables
    # [+input_exprs+] input expressions
    # [+input_tuples+] input tuples
    def make_input_auto_variables(input_exprs, input_tuples)
      input_exprs.each_with_index do |expr, index|
        make_io_auto_variables(:input, expr, input_tuples[index], index+1)
      end
    end

    # Make output auto-variables.
    # [+output_exprs+] output expressions
    # [+output_tuples+] output tuples
    def make_output_auto_variables(output_exprs, output_tuples)
      output_exprs.each_with_index do |expr, index|
        make_io_auto_variables(:output, expr, output_tuples[index], index+1)
      end
    end

    private

    # Make input or output auto variables.
    def make_io_auto_variables(type, expr, data, index)
      prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
      case expr.modifier
      when :all
        make_io_auto_variables_by_all(type, prefix, expr, data)
      when :each
        make_io_auto_variables_by_each(prefix, expr, data)
      end
    end

    # Make input or output auto variables for 'exist' modified data name
    # expression.
    def make_io_auto_variables_by_each(prefix, expr, tuple)
      return if tuple.nil?
      set(Variable.new(prefix), PioneString.new(tuple.name))
      set(Variable.new("#{prefix}.URI"), PioneString.new(tuple.uri))
      expr.match(tuple.name).to_a.each_with_index do |str, i|
        next if i == 0
        set(Variable.new("#{prefix}.*"), PioneString.new(str)) if i == 1
        set(Variable.new("#{prefix}.MATCH[#{i}]"), PioneString.new(str))
      end
    end

    # Make input or output auto variables for 'all' modified data name
    # expression.
    def make_io_auto_variables_by_all(type, prefix, expr, tuples)
      # FIXME: output
      return if type == :output

      set(Variable.new(prefix), PioneString.new(tuples.map{|t| t.name}.join(DataExpr::SEPARATOR)))
      tuples.each_with_index do |tuple, i|
        _prefix = "#{prefix}[#{i+1}]"
        set(Variable.new(_prefix), PioneString.new(tuple.name))
        expr.match(tuple.name).to_a.each_with_index do |str, ii|
          next if ii == 0
          set(Variable.new("#{_prefix}.*"), PioneString.new(str)) if ii == 1
          set(Variable.new("#{_prefix}.MATCH[#{ii}]"), PioneString.new(str))
        end
      end
    end
  end
end
