module Pione
  # DataFinder finds data tuples from tuple space server.
  class DataFinder < PioneObject

    # DataFinderResult represents an element of DataFinder#find results. The
    # attribute +combination+ is a rule inputs combination and +variable_table+
    # is a variable table including variables for found date set.
    class DataFinderResult < Struct.new(:combination, :variable_table)
      # Returns true if the combination is empty.
      # @return [Boolean]
      #   true if the result is empty
      def empty?
        self[:combination].empty?
      end
    end

    include TupleSpaceServerInterface

    # Creates a new finder.
    # @param [TupleSpaceServer] ts_server
    #   tuple space server
    # @param [String] domain
    #   target data domain to find
    def initialize(ts_server, domain)
      set_tuple_space_server(ts_server)
      @domain = domain
    end

    # Find tuple combinations by data expressions from tuple space server.
    # @param [Symbol] type
    #   :input if target date is for input or :output
    # @param [DataExpr] exprs
    #   data-expr list
    # @param [VariableTable] vtable
    #   variabel table
    # @return [DataFinderResult]
    #   result data set
    def find(type, exprs, vtable)
      raise ArgumentError.new(vtable) unless vtable.kind_of?(VariableTable)

      # variable table
      new_vtable = VariableTable.new(vtable)
      case type
      when :input
        # alias for I
        new_vtable.set(Variable.new("INPUT"), Variable.new("I"))
      when :output
        # alias for O
        new_vtable.set(Variable.new("OUTPUT"), Variable.new("O"))
      end

      find_rec(type, exprs, 1, new_vtable)
    end

    private

    # Finds all data tuples by the expression from a tuple space server.
    #
    # @param [DataExpr] expr
    #   query expression of data
    # @return [DataFinderResult]
    #   query result
    def find_by_expr(expr)
      name = expr
      name = expr.first if expr.kind_of?(DataExprSequence)
      name = DataExpr.new(expr) if expr.kind_of?(String)
      query = Tuple[:data].new(name: name, domain: @domain)
      return tuple_space_server.read_all(query).map do |tuple|
        tuple.update_criteria = expr.update_criteria if expr.kind_of?(DataExprSequence)
        tuple
      end
    end

    # Find input tuple combinatioins recursively.
    #
    # @param type [Symbol]
    #   input or output
    # @param exprs [Array<DataExpr>]
    #   data expressions
    # @param index
    #   index
    # @param vtable [VariableTable]
    #   variable table
    # @return [Array<DataFinderResult>]
    #   the result
    def find_rec(type, exprs, index, vtable)
      # return empty when we reach the recuirsion end
      return [DataFinderResult.new([], vtable)] if exprs.empty?

      # expand variables and compile to regular expression
      head = exprs.first.eval(vtable)
      tail = exprs.drop(1)

      # find an input data by name from tuple space server
      tuples = find_by_expr(head)

      # the case for accepting noexistance data
      if tuples.empty? and head.accept_nonexistence?
        return find_rec_sub(type, tail, index, tuples, vtable)
      end

      # make combination results
      prefix = (type == :input ? "I" : "O")
      if head.all?
        # case all distribution
        new_vtable =
          make_auto_variables_by_all(type, prefix, head, tuples, vtable, index)
        unless tuples.empty?
          return find_rec_sub(type, tail, index, tuples, new_vtable)
        end
      else
        # case each distribution
        return tuples.map {|tuple|
          args = [prefix, head, tuple, vtable, index]
          new_vtable = make_auto_variables_by_each(*args)
          find_rec_sub(type, tail, index, tuple, new_vtable)
        }.flatten
      end

      # available combinations were not found
      return []
    end

    # @api private
    def find_rec_sub(type, tail, index, data, vtable)
      find_rec(type, tail, index+1, vtable).map do |res|
        new_combination = res.combination.unshift(data)
        new_vtable = res.variable_table
        DataFinderResult.new(new_combination, new_vtable)
      end
    end

    # Make auto-variables by the name modified 'all'.
    # @api private
    def make_auto_variables_by_all(type, prefix, expr, tuples, vtable, index)
      # create new table
      new_vtable = VariableTable.new(vtable)
      # set auto variables
      new_vtable.make_io_auto_variables_by_all(type, prefix, expr, tuples, index)

      return new_vtable
    end

    # Make auto-variables by the name with 'each' distribution.
    # @api private
    def make_auto_variables_by_each(prefix, expr, tuple, vtable, index)
      # create new table
      new_vtable = VariableTable.new(vtable)
      # set auto variables
      new_vtable.make_io_auto_variables_by_each(prefix, expr, tuple, index)

      return new_vtable
    end
  end
end
