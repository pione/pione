# @api private
module Rinda
  class Tuple
    def ==(other)
      return false unless other.kind_of?(Tuple)
      value == other.value
    end
    alias :eql? :"=="

    def init_with_ary(ary)
      @tuple = Array.new(ary.size)
      # add timestamp
      @tuple.timestamp = ary.timestamp
      @tuple.size.times do |i|
        @tuple[i] = ary[i]
      end
    end
  end

  class TupleEntry
    def ==(other)
      return false unless other.kind_of?(TupleEntry)
      value == other.value
    end
    alias :eql? :"=="
  end

  class TupleBag
    class TupleBin
      def elements
        @bin
      end
    end

    # DomainTupleBin is a domain based TupleBin class.
    # @note
    #   DomainTupleBin should take tuples that have it's domain only.
    class DomainTupleBin < TupleBin
      # Creates a new bin.
      def initialize
        @bin = {}
      end

      def elements
        @bin.values
      end

      # Adds the tuple.
      # @param [Array] tuple
      #   the tuple
      # @return [void]
      def add(tuple)
        if dom = domain(tuple)
          @bin[dom] = tuple
        else
          raise RuntimeError
        end
      end

      # Deletes the tuple.
      # @param [Array] tuple
      #   the tuple
      # @return [void]
      def delete(tuple)
        @bin.delete(domain(tuple))
      end

      # Deletes tuples that match the block.
      # @yield [Array]
      #   each tuple
      # @return [void]
      def delete_if
        return @bin unless block_given?
        @bin.delete_if {|key, val| yield(val)}
      end

      # Finds a tuple matched by the template. This method searches by index
      # when the template has the domain, otherwise by liner.
      # @param [TemplateEntry] template
      #   template tuple
      # @yield [Array]
      #   match condition block
      # @return [Array]
      #   a matched tuple
      def find(template, &b)
        if key = domain(template)
          # indexed search
          return @bin[key]
        else
          # liner search
          return @bin.values.find {|val| yield(val)}
        end
      end

      # Finds all tuples matched by the template. This method searches by index
      # when the template has the domain, otherwise by liner.
      # @param [TemplateEntry] template
      #   template tuple
      # @yield [Array]
      #   match condition block
      # @return [Array<Array>]
      #   matched tuples
      def find_all(template, &b)
        return @bin.values unless block_given?
        if key = domain(template)
          # indexed search
          return [@bin[key]]
        else
          # liner search
          return @bin.select{|_, val| yield(val)}.values
        end
      end

      # Returns an iterator of the values.
      # @return [Enumerator]
      #   iterator of the values
      def each(*args)
        @bin.values.each(*args)
      end

      def size
        @bin.keys.size
      end

      private

      # Returns domain position.
      # @param [Array] tuple
      #   the tuple
      # @return [String]
      #   the domain
      def domain(tuple)
        identifier = tuple.value[0]
        pos = Pione::Tuple[identifier].domain_position
        tuple.value[pos]
      end
    end

    # DataTupleBin is a set of domains.
    class DataTupleBin < TupleBin
      def initialize
        @bin = {}
      end

      def elements
        @bin.values.map{|val| val.values}.flatten
      end

      # Adds the tuple.
      # @param [Array] tuple
      #   the tuple
      # @return [void]
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

      def size
        elements.size
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

    # HashTupleBin is a double hash base bin class.
    class HashTupleBin
      def initialize
        @bin = {}
      end

      def elements
        @bin.values
      end

      def add(tuple)
        @bin[key(tuple)] = tuple
      end

      def delete(tuple)
        @bin.delete(key(tuple))
      end

      def delete_if
        if block_given?
          @bin.delete_if {|_, val| yield(val)}
        end
        return @bin
      end

      def find(template, &b)
        if key(template) && @bin.has_key?(key(template))
          tuple = @bin[key(template)]
          return tuple if yield(tuple)
        else
          @bin.values.each do |tuple|
            return tuple if yield(tuple)
          end
        end
        return nil
      end

      def find_all(template, &b)
        if key(template) && @bin.has_key?(key(template))
          tuple = @bin[key(template)]
          return tuple if yield(tuple)
        else
          return @bin.values.find_all {|tuple|
            yield(tuple)
          }
        end
      end

      def each(*args)
        @bin.values.each(*args)
      end

      private

      # Returns the key.
      def key(tuple)
        # 0:identifier, 1:key, 2:value
        return tuple.value[1]
      end
    end

    # Sets special bin class table by identifier.
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
      return @special_bin.has_key?(key) ? @special_bin[key] : TupleBin
    end

    alias :orig_find :find
    alias :orig_find_all :find_all

    public

    def all_tuples
      @hash.values.map{|bin| bin.elements}.flatten
    end

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

    def task_size
      @hash[:task].size
    end

    def working_size
      @hash[:working].size
    end

    def finished_size
      @hash[:finished].size
    end

    def data_size
      @hash[:data].size
    end
  end

  # @api private
  class TupleSpace
    alias :orig_initialize :initialize

    def initialize(*args)
      orig_initialize(*args)
      @bag.set_special_bin(
        :task => TupleBag::DomainTupleBin,
        :finished => TupleBag::DomainTupleBin,
        :working => TupleBag::DomainTupleBin,
        :data => TupleBag::DataTupleBin,
        :shift => TupleBag::HashTupleBin
      )
    end

    alias :orig_read :read
    def read(tuple, sec=nil)
      shift_tuple(orig_read(tuple, sec))
    end

    alias :orig_read_all :read_all
    def read_all(tuple)
      orig_read_all(tuple).map do |res|
        shift_tuple(res)
      end
    end

    alias :orig_write :write
    def write(tuple, *args)
      tuple.timestamp = Time.now
      orig_write(tuple, *args)
    end

    # Returns all tuples in the space.
    # @param [Symbol] target
    #   tuple type(:all, :bag, :read_waiter, or :take_waiter)
    # @return [Array]
    #   all tuples
    def all_tuples(target=:bag)
      case target
      when :all
        all_tuples(:bag) + all_tuples(:read_waiter) + all_tuples(:take_waiter)
      when :bag
        @bag.all_tuples.map{|tuple| tuple.value}
      when :read_waiter
        @read_waiter.all_tuples.map{|tuple| tuple.value}
      when :take_waiter
        @take_waiter.all_tuples.map{|tuple| tuple.value}
      end
    end

    def task_size
      @bag.task_size
    end

    def working_size
      @bag.working_size
    end

    def finished_size
      @bag.finished_size
    end

    def data_size
      @bag.data_size
    end

    private

    def shift_tuple(tuple)
      if Pione::Tuple[tuple.first]
        if pos = Pione::Tuple[tuple.first].uri_position
          if new_uri = shift_uri(tuple[pos])
            tuple = tuple.clone
            tuple[pos] = new_uri
          end
        end
      end
      return tuple
    end

    def shift_uri(uri, old=[])
      return nil if old.include?(uri)

      template = TemplateEntry.new([:shift, uri, nil])
      if shift_tuple = @bag.find(template)
        next_uri = shift_tuple[2]
        if last_uri = shift_uri(next_uri, old + [uri])
          next_uri = last_uri
        end
        return next_uri
      end
      return nil
    end
  end
end
