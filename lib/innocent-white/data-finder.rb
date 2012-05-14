require 'innocent-white/common'

module InnocentWhite
  class DataFinderResult < Struct.new(:data, :variables)
    def empty?
      self[:data].empty?
    end
  end

  # DataFinder finds data from tuple space server.
  class DataFinder < InnocentWhiteObject
    include TupleSpaceServerInterface

    def initialize(ts_server, domain)
      set_tuple_space_server(ts_server)
      @domain = domain
    end

    # Find data tuple by data expression from a tuple space server.
    def find_by_expr(expr)
      name = DataExpr.new(name) if name.kind_of?(String)
      q = Tuple[:data].new(name: expr, domain: @domain)
      tuple_space_server.read_all(q)
    end

    # Find input tuple combinations by input expressions from tuple space
    # server.
    def find(type, exprs, variable_table=VariableTable.new)
      find_rec(type, exprs, 1, variable_table)
    end

    private

    # Find input tuple combinatioins recursively.
    def find_rec(type, exprs, index, variable_table)
      # return empty when we reach the recuirsion end
      return [DataFinderResult.new([], variable_table)] if exprs.empty?

      # expand variables and compile to regular expression
      head = exprs.first.with_variable_table(variable_table)
      tail = exprs.drop(1)

      # find an input data by name from tuple space server
      tuples = find_by_expr(head)

      # make combination results
      if head.all?
        # case all modifier
        new_variable_table =
          make_auto_variables_by_all(type, head, index, tuples, variable_table)
        unless tuples.empty?
          return find_rec_sub(type, tail, index, tuples, new_variable_table)
        end
      else
        # case each modifier
        return tuples.map {|tuple|
          args = [type, head, index, tuple, varriable_table]
          new_variable_table = make_auto_variables_by_each(*args)
          find_rec_sub(type, tail, index, tuple, new_variable_table)
        }.flatten
      end

      # available combinations were not found
      return []
    end

    def find_rec_sub(type, tail, index, data, vars)
      find_rec(type, tail, index+1, vars).map do |res|
        new_data = res.data.unshift(data).flatten
        new_vars = res.variables
        DataFinderResult.new(new_data, new_vars)
      end
    end

    # Make auto-variables by the name modified 'all'.
    def make_auto_variables_by_all(type, expr, index, tuples, vars)
      new_vars = vars.clone
      prefix = type == :input ? "INPUT" : "OUTPUT"
      new_vars["#{prefix}[#{index}]"] =
        tuples.map{|t| t.name}.join(DataExpr::SEPARATOR)
      return new_vars
    end

    # Make auto-variables by the name modified 'each'.
    def make_auto_variables_by_each(type, expr, index, tuple, vars)
      new_vars = vars.clone
      prefix = type == :input ? "INPUT" : "OUTPUT"
      md = expr.match(tuple.name)
      new_vars["#{prefix}[#{index}]"] = tuple.name
      new_vars["#{prefix}[#{index}].URI"] = tuple.uri
      md.to_a.each_with_index do |s, i|
        new_vars["#{prefix}[#{index}].*"] = s if i == 1
        new_vars["#{prefix}[#{index}].MATCH[#{i}]"] = s
      end
      return new_vars
    end
  end
end
