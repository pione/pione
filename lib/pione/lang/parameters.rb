module Pione
  module Lang
    # ParameterSet is a piece class for set of actual parameters.
    class ParameterSet < Piece
      include Enumerable
      member :table, default: lambda { Hash.new }

      forward! Proc.new{table}, :each, :keys, :[]

      # Evaluate the object with variable table.
      def eval(env)
        set(table: Hash[*table.map{|key, val| [key, val.eval(env)]}.flatten(1)])
      end

      # Merge values of the other parameter set.
      def merge(other)
        set(table: table.merge(other.table))
      end

      # Return a parameter set that match the names.
      def filter(names)
        set(table: table.select{|key, _| names.include?(key)})
      end

      # Return a parameter set excluding the names.
      def delete_all(names)
        set(table: table.reject{|key, _| names.include?(key)})
      end

      # Merge default values of the rule condition.
      def merge_default_values(rule_condition)
        tbl = Hash.new

        rule_condition.param_definition.each do |key, param_definition|
          unless keys.include?(key)
            tbl[key] = param_definition.value
          end
        end

        set(table: table.merge(tbl))
      end

      def textize
        "{" + table.keys.sort.map{|k| "%s:%s" % [k, table[k].textize]}.join(", ") + "}"
      end

      # Expand parameter value sequences.
      def expand
        if block_given?
          array = table.map do |k, v|
            [k, (v.respond_to?(:each) and v.distribution == :each) ? v.each : v]
          end
          find_atomic_composites(array, Hash.new) do |t|
            yield set(table: t.inject(Hash.new){|h, (k, v)| h.merge(k => v)})
          end
        else
          Enumerator.new(self, :expand)
        end
      end

      # Find atomic parameters recursively.
      def find_atomic_composites(array, table, &b)
        # end recursion
        return b.call(table) if array.empty?

        # find atomic composites
        key, enum = array.first
        tail = array.drop(1)
        loop do
          if enum.kind_of?(Enumerator)
            find_atomic_composites(tail, table.merge(key => enum.next), &b)
          else
            find_atomic_composites(tail, table.merge(key => enum), &b)
            raise StopIteration
          end
        end
        enum.rewind if enum.kind_of?(Enumerator)
      end

      def to_json(*args)
        table.to_json(*args)
      end

      def ==(other)
        return false unless other.kind_of?(self.class)
        table == other.table
      end
      alias :eql? :"=="
    end

    class ParameterSetSequence < OrdinalSequence
      set_pione_type TypeParameterSet
      piece_class ParameterSet

      def each
        if block_given?
          pieces.each {|piece| piece.each {|pset| yield set(pieces: [pset])}}
        else
          Enumerator.new(self, :each)
        end
      end

      def merge(other)
        if pieces.empty?
          set(pieces: other.pieces)
        else
          map2(other) do |rec_piece, other_piece|
            rec_piece.set(table: rec_piece.table.merge(other_piece.table))
          end
        end
      end
    end

    TypeParameterSet.instance_eval do
      # Compound parameters.
      define_deferred_pione_method("+", [TypeParameterSet], TypeParameterSet) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.set(table: rec_piece.table.merge(other_piece.table))
        end
      end

      define_pione_method("as_string", [], TypeString) do |env, rec|
        StringSequece.of(rec.textize)
      end
    end
  end
end
