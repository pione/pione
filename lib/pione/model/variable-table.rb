require 'pione/common'

module Pione::Model

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
      @table[var]
    end

    # Set a new variable.
    def set(var, val)
      if old = @table[var] and not(val == old)
        raise VariableBindingError.new(var, val, old)
      end
      @table[var] = val
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

    # Expand variables in the string.
    def expand(str)
      variables = to_hash
      str.gsub(/\{\$(.+?)\}/) do
        if variables.has_key?($1)
          variables[$1]
        else
          raise UnknownVariableError.new($1)
        end
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
      set(prefix, tuple.name)
      set("#{prefix}.URI", tuple.uri)
      expr.match(tuple.name).to_a.each_with_index do |str, i|
        next if i == 0
        set("#{prefix}.*", str) if i == 1
        set("#{prefix}.MATCH[#{i}]", str)
      end
    end

    # Make input or output auto variables for 'all' modified data name
    # expression.
    def make_io_auto_variables_by_all(type, prefix, expr, tuples)
      # FIXME: output
      return if type == :output

      set(prefix, tuples.map{|t| t.name}.join(DataExpr::SEPARATOR))
      tuples.each_with_index do |tuple, i|
        _prefix = "#{prefix}[#{i+1}]"
        set(_prefix, tuple.name)
        expr.match(tuple.name).to_a.each_with_index do |str, ii|
          next if ii == 0
          set("#{_prefix}.*", str) if ii == 1
          set("#{_prefix}.MATCH[#{ii}]", str)
        end
      end
    end
  end
end
