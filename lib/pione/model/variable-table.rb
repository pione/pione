module Pione
  module Model
    # UnboundVariableError represents an unknown variable reference.
    class UnboundVariableError < StandardError
      attr_reader :variable

      # Create an error.
      #
      # @param variable [Variable]
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

      # Create an error.
      #
      # @param variable [Variable]
      #   double bound variable
      # @param new_value [BasicModel]
      #   new value
      # @param old_value [BasicModel]
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
    class VariableTable < BasicModel
      # Return empty variable table.
      #
      # @return [VariableTable]
      #   empty variable table
      def self.empty
        new
      end

      # Create a vairable table.
      #
      # @param table [Hash{Variable => BasicModel}]
      #   initial values for the variable table
      def initialize(table={})
        @table = table.to_hash.dup
        super()
      end

      # Return the variable table as hash.
      #
      # @return [Hash{Variable => BasicModel}]
      #   hash form of the variable table
      def to_hash
        @table
      end

      # Return the parameters form.
      #
      # @return [Parameters]
      #   parameters form of the variable table
      def to_params
        Parameters.new(to_hash)
      end

      # Return true if the table is empty.
      #
      # @return [Boolean]
      #   true if the table is empty
      def empty?
        @table.empty?
      end

      # Gets the variable value and evaluates the value if the value is not
      # atomic.
      #
      # @param var [Variable]
      #   table key to get the value
      # @return [BasicModel]
      #   the value
      def get(var)
        check_argument_type(var, Variable)
        val = @table[var]
        case val
        when Variable
          next_val = get(val)
          return next_val.nil? ? val : next_val
        when BasicModel
          return not(val.atomic?) ? val.eval(self) : val
        end
        return val
      end

      # Set a new variable. This method raises an exception when the variable has
      # its value already.
      #
      # @param variable [Variable]
      #   table key
      # @param new_value [BasicModel]
      #   new value
      # @return [VariableTable]
      #   new variable table
      def set(variable, new_value)
        check_argument_type(variable, Variable)
        check_argument_type(new_value, BasicModel)
        if old_value = @table[variable]
          unless old_value.nil? or old_value.void? or new_value == old_value
            raise VariableBindingError.new(variable, new_value, old_value)
          end
        end
        @table[variable] = new_value
        return self
      end

      # Set a variable. This method overrides old variable value.
      #
      # @param variable [Variable]
      #   table key
      # @param new_value [BasicModel]
      #   new value
      # @return [void]
      def set!(variable, new_value)
        check_argument_type(variable, Variable)
        check_argument_type(new_value, BasicModel)
        @table[variable] = new_value
      end

      # Expand variables in the string.
      #
      # @param str [String]
      #   string
      # @return [String]
      #   expanded string
      def expand(str)
        variables = to_hash
        new_str = str.to_s.gsub(/\{(\$.+?)\}/) do
          expr = DocumentTransformer.new.apply(DocumentParser.new.expr.parse($1))
          expr.eval(self).call_pione_method(self, "textize").first.value
        end
        new_str.gsub(/\<\?\s*(.+?)\s*\?\>/) do
          expr = DocumentTransformer.new.apply(DocumentParser.new.expr.parse($1))
          expr.eval(self).call_pione_method(self, "textize").first.value
        end
      end

      # Return key variables of the table.
      #
      # @return [Array<Variable>]
      #   variable as table keys
      def variables
        @table.keys
      end

      # FIXME
      # Return true if the string includes variables.
      #
      # @param str [String]
      #   target string
      # @return [Boolean]
      #   true if the string includes variables
      def self.check_include_variable(str)
        str = str.to_s
        return true if /\{\$(.+?)\}/.match(str)
        str.gsub(/\<\?\s*(.+?)\s*\?\>/) do
          expr = DocumentTransformer.new.apply(DocumentParser.new.expr.parse($1))
          return true if expr.include_variable?
        end
        return false
      end

      # Return true if table's values include variables.
      #
      # @return [Boolean]
      #   true if table's values include variables
      def include_variable?
        # FIXME
        @table.values.any?{|val| val.include_variable?}
      end

      # Make input auto-variables.
      #
      # @param input_exprs [Array<DataExpr>]
      #   input expressions
      # @param input_tuples [Array<Expr>]
      #   input tuples
      # @return [void]
      def make_input_auto_variables(input_exprs, input_tuples)
        set(Variable.new("INPUT"), Variable.new("I"))
        input_exprs.each_with_index do |expr, index|
          make_io_auto_variables(:input, expr, input_tuples[index], index+1)
        end
      end

      # Make output auto-variables.
      #
      # @param output_exprs [Array<DataExpr>]
      #   output expressions
      # @param output_tuples [Array<DataExpr>]
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

      # Make input or output auto variables.
      #
      # @api private
      def make_io_auto_variables(type, expr, data, index)
        expr = expr.eval(self)
        prefix = (type == :input ? "I" : "O")
        case expr.distribution
        when :all
          make_io_auto_variables_by_all(type, prefix, expr, data, index)
        when :each
          make_io_auto_variables_by_each(prefix, expr, data, index)
        end
      end

      # Make input/output auto variables by data expression with each
      # distribution.
      #
      # @param prefix [String]
      #   "I" or "O"
      # @param expr [DataExpr]
      #   data expression
      # @param tuple [DataTuple]
      #   data tuple
      # @param index [Integer]
      #   index number of the input/output
      # @return [void]
      def make_io_auto_variables_by_each(prefix, expr, tuple, index)
        return if tuple.nil?

        # variable
        var = Variable.new(prefix)

        # matched data
        md = expr.first.match(tuple.name).to_a

        # setup data expression sequence
        seq = get(var) || KeyedSequence.empty
        data_expr = DataExpr.new(tuple.name, location: tuple.location, matched_data: md)

        # update variable table
        set!(var, seq.put(PioneInteger.new(index), data_expr))

        # set the special variable if index is 1
        if prefix == 'I' && index == 1
          set(Variable.new("*"), StringSequence.new([PioneString.new(md[1])]))
        end
      end

      # Make input/output auto variables by data expression with all
      # distribution.
      #
      # @param prefix [String]
      #   "I" or "O"
      # @param expr [DataExpr]
      #   data expression
      # @param tuple [DataTuple]
      #   data tuple
      # @param index [Integer]
      #   index number of the input/output
      # @return [void]
      def make_io_auto_variables_by_all(type, prefix, expr, tuples, index)
        # FIXME: output
        return if type == :output

        # variable
        var = Variable.new(prefix)

        # setup data expression sequence(this is $I/$O)
        seq = get(var) || KeyedSequence.empty

        asterisk = []

        # convert each tuples
        matched_seq = tuples.inject(seq) do |_seq, tuple|
          # matched data
          md = expr.first.match(tuple.name).to_a
          asterisk << md[1]

          # make a date expression
          data_expr = DataExpr.new(tuple.name, location: tuple.location, matched_data: md)

          # put it with index
          _seq.put(PioneInteger.new(index), data_expr)
        end

        # set special variable if index equals 1
        if prefix == 'I' && index == 1
          strs = asterisk.map{|str| PioneString.new(str)}
          set(Variable.new("*"), StringSequence.new(strs))
        end

        # update sequence
        set!(var, matched_seq)
      end
    end
  end
end
