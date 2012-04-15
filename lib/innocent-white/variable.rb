require 'innocent-white/common'

module InnocentWhite

  # Variable represents variables in rules.
  class Variable
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def ==(other)
      return false unless other.kind_of?(Variable)
      @name == other.name
    end

    alias :eql? :==

    def hash
      @name.hash
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

  # VariableTable representes a variable table of the excuting rule.
  class VariableTable < InnocentWhiteObject
    def initialize
      @data = {}
    end

    def get(var)
      var = variable_name(var)
      val = @data[var]
      if val.kind_of?(Variable)
        val = get(val)
      end
      return val
    end

    def set(var, val)
      var = variable_name(var)
      if old = get(var) and not(val == old)
        raise VariableBindingError.new(var, val, old)
      end
      @data[var] = val
    end

    # Expands variables in the string using relations in the table.
    def expand_string(str)
      str.gsub(/\{\$(.+?)\}/) do
        if res = get($1)
          res
        else
          raise UnknownVariableError.new($1)
        end
      end
    end

    private

    def variable_name(var)
      raise ArgumentError.new(var) unless var.kind_of?(Variable) or var.kind_of?(String)
      var = Variable.new(var) if var.kind_of?(String)
      return var
    end

  end
end
