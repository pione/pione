require 'innocent-white/common'

module InnocentWhite
  class VariableBindingError < StandardError
    attr_reader :name
    attr_reader :value
    attr_reader :old

    def initialize(name, value, old)
      @name = name
      @value = value
      @old = old
      super("Try to bind the value '#{value}' as variable '#{name}'," +
            "but already bound the value '#{old}'")
    end
  end

  # VariableTable represents variable table for rule and data finder.
  class VariableTable < InnocentWhiteObject
    # Make an auto vairable table.
    def initialize(table={})
      @table = table.clone
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
      Util.expand_variables(str, to_hash)
    end

    private

    # Make input or output auto variables.
    def make_io_auto_variables(type, expr, data, index)
      prefix = make_prefix(type, index)
      case expr.modifier
      when :all
        make_io_auto_variables_by_all(type, expr, data, prefix)
      when :each
        make_io_auto_variables_by_each(type, expr, data, prefix)
      end
    end

    # :nodoc:
    def make_prefix(type, index)
      prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
    end

    # Make input or output auto variables for 'exist' modified data name
    # expression.
    def make_io_auto_variables_by_each(type, expr, data, prefix)
      return if data.nil?
      @table[prefix] = data.name
      @table["#{prefix}.URI"] = data.uri
      expr.match(data.name).to_a.each_with_index do |s, i|
        next if i == 0
        @table["#{prefix}.*"] = s if i == 1
        @table["#{prefix}.MATCH[#{i}]"] = s
      end
    end

    # Make input or output auto variables for 'all' modified data name
    # expression.
    def make_io_auto_variables_by_all(type, expr, tuples, prefix)
      # FIXME: output
      return if type == :output
      @table[prefix] = tuples.map{|t| t.name}.join(DataExpr::SEPARATOR)
      tuples.each_with_index do |t, i|
        _prefix = "#{prefix}[#{i+1}]"
        @table[_prefix] = t.name
        expr.match(t.name).to_a.each_with_index do |s, ii|
          next if ii == 0
          @table["#{_prefix}.*"] = s if ii == 1
          @table["#{_prefix}.MATCH[#{ii}]"] = s
        end
      end
    end
  end
end
