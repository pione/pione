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
    def find(type, exprs, vars={})
      find_rec(type, exprs, 1, {})
    end

    private

    # Find input tuple combinatioins recursively.
    def find_rec(type, exprs, index, vars)
      # return empty when we reach the recuirsion end
      return [DataFinderResult.new([], vars)] if exprs.empty?

      # expand variables and compile to regular expression
      head = exprs.first.with_variables(vars)
      tail = exprs.drop(1)

      # find an input data by name from tuple space server
      tuples = find_by_expr(head)

      # make combination results
      if head.all?
        # case all modifier
        _vars = make_auto_variables_by_all(type, head, index, tuples, vars)
        unless tuples.empty?
          return find_rec_sub(type, tail, index, tuples, _vars)
        end
      else
        # case each modifier
        return tuples.map {|tuple|
          _vars = make_auto_variables_by_each(type, head, index, tuple, vars)
          find_rec_sub(type, tail, index, tuple, _vars)
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
