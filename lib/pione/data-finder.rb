require 'pione/common'

module Pione
  # DataFinder finds data from tuple space server.
  class DataFinder < PioneObject
    # DataFinderResult represents result elements of
    # DataFinder#find. +combination+ is rule inputs and +variable_table+ is
    # found variable's table.
    class DataFinderResult < Struct.new(:combination, :variable_table)
      # Return true if the combination is empty.
      def empty?
        self[:combination].empty?
      end
    end

    include TupleSpaceServerInterface

    # Create a new finder.
    # [+ts_server+] tuple space server
    # [+domain+] target data domain to find
    def initialize(ts_server, domain)
      set_tuple_space_server(ts_server)
      @domain = domain
    end

    # Find data tuple by data expression from a tuple space server.
    def find_by_expr(expr)
      expr = DataExpr.new(expr) if expr.kind_of?(String)
      q = Tuple[:data].new(name: expr, domain: @domain)
      tuple_space_server.read_all(q)
    end

    # Find tuple combinations by data expressions from tuple space server.
    def find(type, exprs, vtable)
      raise ArgumentError.new(vtable) unless vtable.kind_of?(VariableTable)
      find_rec(type, exprs, 1, vtable)
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
      prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
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
          args = [prefix, head, tuple, vtable]
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
      new_vtable = VariableTable.new(vtable)
      list = tuples.map{|t| t.name}.join(DataExpr::SEPARATOR)
      new_vtable.set(
        Variable.new(prefix),
        PioneString.new(list)
      )
      return new_vtable
    end

    # Make auto-variables by the name modified 'each'.
    def make_auto_variables_by_each(prefix, expr, tuple, vtable)
      new_vtable = VariableTable.new(vtable)
      md = expr.match(tuple.name)
      new_vtable.set(
        Variable.new(prefix),
        PioneString.new(tuple.name)
      )
      new_vtable.set(
        Variable.new("#{prefix}.URI"),
        PioneString.new(tuple.uri)
      )
      md.to_a.each_with_index do |str, i|
        if i == 1
          new_vtable.set(
            Variable.new("#{prefix}.*"),
            PioneString.new(str)
          )
        end
        new_vtable.set(
          Variable.new("#{prefix}.MATCH[#{i}]"),
          PioneString.new(str)
        )
      end
      return new_vtable
    end
  end
end
