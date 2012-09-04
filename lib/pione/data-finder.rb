require 'pione/common'

module Pione
  # DataFinder finds data from tuple space server.
  class DataFinder < PioneObject

    # DataFinderResult represents an element of DataFinder#find results. The
    # attribute +combination+ is a rule inputs combination and +variable_table+
    # is a variable's table including variables for found date set.
    class DataFinderResult < Struct.new(:combination, :variable_table)
      # Return true if the combination is empty.
      def empty?
        self[:combination].empty?
      end
    end

    include TupleSpaceServerInterface

    # Creates a new finder.
    # [+ts_server+] tuple space server
    # [+domain+] target data domain to find
    def initialize(ts_server, domain)
      set_tuple_space_server(ts_server)
      @domain = domain
    end

    # Finds all data tuples by the expression from a tuple space server.
    # [expr] data-expr
    def find_by_expr(expr)
      expr = DataExpr.new(expr) if expr.kind_of?(String)
      q = Tuple[:data].new(name: expr, domain: @domain)
      return tuple_space_server.read_all(q)
    end

    # Find tuple combinations by data expressions from tuple space server.
    # [type] :input or :output
    # [exprs] data-expr list
    # [vtable] variabel table
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

    # Find input tuple combinatioins recursively.
    def find_rec(type, exprs, index, vtable)
      # return empty when we reach the recuirsion end
      return [DataFinderResult.new([], vtable)] if exprs.empty?

      # expand variables and compile to regular expression
      head = exprs.first.eval(vtable)
      tail = exprs.drop(1)

      # find an input data by name from tuple space server
      tuples = find_by_expr(head)

      # make combination results
      prefix = (type == :input ? "I" : "O")
      if head.all?
        # case all modifier
        new_vtable =
          make_auto_variables_by_all(prefix, head, tuples, vtable)
        unless tuples.empty?
          return find_rec_sub(type, tail, index, tuples, new_vtable)
        end
      else
        # case each modifier
        return tuples.map {|tuple|
          args = [prefix, head, tuple, vtable, index]
          new_vtable = make_auto_variables_by_each(*args)
          find_rec_sub(type, tail, index, tuple, new_vtable)
        }.flatten
      end

      # available combinations were not found
      return []
    end

    def find_rec_sub(type, tail, index, data, vtable)
      find_rec(type, tail, index+1, vtable).map do |res|
        new_combination = res.combination.unshift(data)
        new_vtable = res.variable_table
        DataFinderResult.new(new_combination, new_vtable)
      end
    end

    # Make auto-variables by the name modified 'all'.
    def make_auto_variables_by_all(prefix, expr, tuples, vtable)
      # create new table
      new_vtable = VariableTable.new(vtable)
      # variable
      var = Variable.new(prefix)

      # setup rule-io list
      list = new_vtable.get(var)
      list = RuleIOList.new unless list
      io_list = RuleIOList.new
      new_vtable.set!(var, list.add(io_list))

      # convert each tuples
      tuples.each do |tuple, i|
        elt = RuleIOElement.new(PioneString.new(tuple.name))
        elt.uri = PioneString.new(tuple.uri)
        elt.match = expr.match(tuple.name).to_a.map{|m| PioneString.new(m)}
        io_list.add!(elt)
      end

      return new_vtable
    end

    # Make auto-variables by the name modified 'each'.
    def make_auto_variables_by_each(prefix, expr, tuple, vtable, index)
      # create new table
      new_vtable = VariableTable.new(vtable)
      # variable
      var = Variable.new(prefix)
      # matched data
      md = expr.match(tuple.name).to_a

      # setup rule-io list
      list = new_vtable.get(var)
      list = RuleIOList.new unless list
      elt = RuleIOElement.new(PioneString.new(tuple.name))
      elt.uri = PioneString.new(tuple.uri)
      elt.match = md.map{|d| PioneString.new(d)}
      new_vtable.set!(var, list.add(elt))

      # set special variable if index equals 1
      if prefix == 'I' && index == 1
        new_vtable.set(Variable.new("*"), PioneString.new(md[1]))
      end

      return new_vtable
    end
  end
end
