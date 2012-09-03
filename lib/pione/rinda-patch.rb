require 'hamster'

module Rinda
  class Tuple
    def ==(other)
      return false unless other.kind_of?(Tuple)
      value == other.value
    end
  end

  class TupleEntry
    def ==(other)
      return false unless other.kind_of?(TupleEntry)
      value == other.value
    end
  end

  class TupleBag
    class TaskTupleBin < TupleBin
      def initialize
        @bin = Hamster.hash
      end

      def add(tuple)
        @bin = @bin.put(key(tuple), tuple)
      end

      def delete(tuple)
        @bin = @bin.delete(key(tuple))
      end

      def delete_if
        return @bin unless block_given?
        @bin = @bin.filter {|key, val| !yield(val)}
      end

      def find(template, &b)
        if key = key(template)
          return @bin.get(key)
        else
          @bin.values.each do |x|
            return x if yield(x)
          end
        end
        nil
      end

      def find_all(&b)
        return @bin unless block_given?
        @bin.filter {|key, val| yield(key, val)}
      end

      def each(*args)
        @bin.values.each(*args)
      end

      private

      # Returns domain position.
      def key(tuple)
        tuple.value[5]
      end
    end

    # DataTupleBin is a set of domains.
    class DataTupleBin
      def initialize
        @bin = Hamster.hash
      end

      def add(tuple)
        set = @bin.get(domain(tuple)) || Hamster.set
        @bin = @bin.put(domain(tuple), set.add(tuple))
      end

      def delete(tuple)
        set = @bin.get(domain(tuple)) || Hamster.set
        @bin = @bin.puts(domain(tuple), set.delete(tuple))
      end

      def delete_if
        return @bin unless block_given?
        @bin = @bin.filter {|key, val| !yield(val)}
      end

      def find(template, &b)
        if key = key(template)
          return @bin.get(key)
        else
          @bin.values.each do |x|
            return x if yield(x)
          end
        end
        nil
      end

      def find_all(&b)
        return @bin unless block_given?
        set = @bin.values.inject(Hamster.set){|res, elt| res + elt}
        set.filter {|elt| yield(elt)}
      end

      def each(*args)
        set = @bin.values.inject(Hamster.set){|res, elt| res + elt}
        set.each(*args)
      end

      private

      # Returns domain position.
      def domain(tuple)
        tuple.value[1]
      end
    end

    attr_accessor :special_bin

    def push(tuple)
      key = bin_key(tuple)
      prepare_table(key)
      @hash[key].add(tuple)
    end

    def prepare_table(key)
      unless @hash[key]
        @hash[key] = bin_class(key).new
      end
    end

    def bin_class(key)
      return TupleBin unless @special_bin
      return (key == :task ? TaskTupleBin : TupleBin)
    end

    alias :orig_find :find

    public

    def find(template)
      key = bin_key(template)
      if key == :task
        prepare_table(key)
        @hash[key].find(template) do |tuple|
          tuple.alive? && template.match(tuple)
        end
      else
        orig_find(template)
      end
    end
  end

  class TupleSpace
    alias :orig_initialize :initialize

    def initialize(period=60)
      orig_initialize(period)
      @bag.special_bin = true
    end
  end
end
