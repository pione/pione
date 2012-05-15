require 'innocent-white/common'

module InnocentWhite
  # DataFinder finds data from tuple space server.
  class DataFinder < InnocentWhiteObject
    # DataFinderResult represents inner results of DataFinder#find.
    class DataFinderResult < Struct.new(:data, :variables)
      def empty?
        self[:data].empty?
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
      name = DataExpr.new(name) if name.kind_of?(String)
      q = Tuple[:data].new(name: expr, domain: @domain)
      tuple_space_server.read_all(q)
    end

    # Find input tuple combinations by input expressions from tuple space
    # server.
    def find(type, exprs, variable_table=VariableTable.new)
      find_rec(type, exprs, 1, variable_table).to_a
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
      prefix = (type == :input ? "INPUT" : "OUTPUT") + "[#{index}]"
      if head.all?
        # case all modifier
        new_variable_table =
          make_auto_variables_by_all(prefix, head, tuples, variable_table)
        unless tuples.empty?
          return find_rec_sub(type, tail, index, tuples, new_variable_table)
        end
      else
        # case each modifier
        return tuples.map {|tuple|
          args = [prefix, head, tuple, variable_table]
          new_variable_table = make_auto_variables_by_each(*args)
          find_rec_sub(type, tail, index, tuple, new_variable_table)
        }.flatten
      end

      # available combinations were not found
      return []
    end

    def find_rec_sub(type, tail, index, data, variable_table)
      find_rec(type, tail, index+1, variable_table).map do |res|
        new_data = res.data.unshift(data).flatten
        new_variable_table = res.variables
        DataFinderResult.new(new_data, new_variable_table)
      end
    end

    # Make auto-variables by the name modified 'all'.
    def make_auto_variables_by_all(prefix, expr, tuples, variable_table)
      new_variable_table = VariableTable.new(variable_table)
      list = tuples.map{|t| t.name}.join(DataExpr::SEPARATOR)
      new_variable_table.set(prefix, list)
      return new_variable_table
    end

    # Make auto-variables by the name modified 'each'.
    def make_auto_variables_by_each(prefix, expr, tuple, variable_table)
      new_variable_table = VariableTable.new(variable_table)
      md = expr.match(tuple.name)
      new_variable_table.set(prefix, tuple.name)
      new_variable_table.set("#{prefix}.URI", tuple.uri)
      md.to_a.each_with_index do |str, i|
        new_variable_table.set("#{prefix}.*", str) if i == 1
        new_variable_table.set("#{prefix}.MATCH[#{i}]", str)
      end
      return new_variable_table
    end
  end
end
