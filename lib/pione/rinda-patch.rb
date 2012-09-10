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
    class DomainTupleBin < TupleBin
      def initialize
        @bin = {}
      end

      def add(tuple)
        @bin[key(tuple)] = tuple
      end

      def delete(tuple)
        @bin.delete(key(tuple))
      end

      def delete_if
        return @bin unless block_given?
        @bin.delete_if {|key, val| yield(val)}
      end

      # Finds a tuple by the template. This method searches by index when the
      # template has the domain, otherwise by liner.
      def find(template, &b)
        if key = key(template)
          return @bin[key]
        else
          @bin.values.each do |x|
            return x if yield(x)
          end
        end
        return nil
      end

      def find_all(template, &b)
        return @bin.values unless block_given?
        if key = key(template)
          return [@bin[key]]
        else
          @bin.select{|_, val| yield(val)}.values
        end
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
    class DataTupleBin < TupleBin
      def initialize
        @bin = {}
      end

      def add(tuple)
        prepare_table(domain(tuple))
        @bin[domain(tuple)][name(tuple)] = tuple
      end

      def delete(tuple)
        prepare_table(domain(tuple))
        @bin[domain(tuple)].delete(name(tuple))
      end

      def delete_if
        if block_given?
          @bin.values.each do |table|
            table.delete_if {|_, val| yield(val)}
          end
        end
        return @bin
      end

      def find(template, &b)
        domain = domain(template)
        name = name(template)
        prepare_table(domain)
        if domain
          @bin[domain].values.each do |tuple|
            return tuple if yield(tuple)
          end
        else
          @bin.values.each do |table|
            table.values.each do |tuple|
              return tuple if yield(tuple)
            end
          end
        end
        return nil
      end

      def find_all(template, &b)
        domain = domain(template)
        name = name(template)
        prepare_table(domain)

        if domain
          if block_given?
            return @bin[domain].values.select {|tuple| yield(tuple)}
          else
            return @bin[domain].values
          end
        else
          if block_given?
            return @bin.values.map{|table| table.values}.flatten.select{|tuple|
              yield(tuple)
            }
          else
            return @bin.values.map{|table| table.values}.flatten
          end
        end
      end

      def each(*args)
        @bin.values.map{|table| table.values}.flatten.each(*args)
      end

      private

      def prepare_table(domain)
        if domain
          @bin[domain] = {} unless @bin[domain]
        end
      end

      # Returns the domain.
      def domain(tuple)
        return tuple.value[1]
      end

      # Returns the name.
      def name(tuple)
        return tuple.value[2]
      end
    end

    def set_special_bin(special_bin)
      @special_bin = special_bin
    end

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
      return @special_bin[key] ? @special_bin[key] : TupleBin
    end

    alias :orig_find :find
    alias :orig_find_all :find_all

    public

    def find(template)
      key = bin_key(template)
      if @special_bin[key]
        prepare_table(key)
        @hash[key].find(template) do |tuple|
          tuple.alive? && template.match(tuple)
        end
      else
        orig_find(template)
      end
    end

    def find_all(template)
      key = bin_key(template)
      if @special_bin[key]
        prepare_table(key)
        vals = @hash[key].find_all(template) do |tuple|
          tuple.alive? && template.match(tuple)
        end
        return vals
      else
        orig_find_all(template)
      end
    end
  end

  class TupleSpace
    alias :orig_initialize :initialize

    def initialize(period=60)
      orig_initialize(period)
      @bag.set_special_bin(
        :task => TupleBag::DomainTupleBin,
        :data => TupleBag::DataTupleBin
      )
    end
  end
end
