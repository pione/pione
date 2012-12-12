# @api private
module Rinda
  class RedundantTupleError < StandardError
    def initialize(tuple)
      @tuple = tuple
    end

    def message
      "Try to write redundant tuple in tuple space: %s" % @tuple.inspect
    end

    def inspect
      "#<Rinda::RedundantTupleError @tuple=%s>" % @tuple.inspect
    end
    alias :to_s :inspect
  end

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

  class WaitTemplateEntry
    attr_reader :place
    attr_reader :thread
    attr_reader :found
    attr_accessor :signaled
    attr_accessor :finished

    # @note
    #   removed monitor from original
    def initialize(place, ary, expires=nil)
      super(ary, expires)
      @place = place
      @found = nil
      @signaled = false
      @finished = false
    end

    # @note
    #   thread version(don't use monitor)
    def wait
      @thread = Thread.current
      Thread.stop
      @thread = nil
    end

    # @note
    #   thread version(don't use monitor)
    def signal
      @signaled = true
      if @thread && @thread.status == "sleep"
        @thread.run
      end
    end

    def inspect
      infos = [
        "@cancel=%s" % @cancel,
        "@expires=%s" % @expires,
        "@tuple=%s" % @tuple.inspect,
        "@renewer=%s" % @renewer.inspect,
        "@found=%s" % @found.inspect,
        "@thread=%s" % @thread.inspect,
        "@signaled=%s" % @signaled,
        "@finished=%s" % @finished
      ]
      "#<%s:%s %s>" % ["Rinda::WaitTemplateEntry", __id__, infos.join(", ")]
    end
    alias :to_s :inspect

    def ==(other)
      return false unless other.kind_of?(WaitTemplateEntry)
      return false unless value == other.value
      return false unless @thread == other.thread
      return false unless @signaled == other.signaled
      return false unless @finished == other.finished
      return true
    end
    alias :eql? :"=="
  end

  class TupleBag
    # TupleBin is original array based class.
    class TupleBin
      def elements
        @bin
      end

      def size
        elements.size
      end

      def delete(tuple)
        if i = @bin.index(tuple)
          @bin.delete_at(i)
        end
      end
    end

    # DomainTupleBin is a domain based TupleBin class.
    # @note
    #   DomainTupleBin should take tuples that have domain.
    class DomainTupleBin < TupleBin
      # Creates a new bin.
      def initialize
        @bin = {}
      end

      # Adds the tuple.
      # @param [Array] tuple
      #   the tuple
      # @return [void]
      def add(tuple)
        if dom = domain(tuple)
          unless @bin[dom]
            @bin[dom] = tuple
          else
            raise RedundantTupleError.new(tuple.value)
          end
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

      def elements
        @bin.values
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
        unless @bin[domain(tuple)][name(tuple)]
          @bin[domain(tuple)][name(tuple)] = tuple
        else
          raise RedundantTupleError.new(tuple.value)
        end
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

    # HashTupleBin is a hash based bin class.
    class HashTupleBin
      def initialize
        @bin = {}
      end

      def elements
        @bin.values
      end

      def add(tuple)
        unless @bin[key(tuple)]
          @bin[key(tuple)] = tuple
        else
          raise RedundantErrorTuple.new(tuple)
        end
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

    def initialize
      @hash = {}
      @mutex = Mutex.new
      @enum = enum_for(:each_entry)
      @special_bin = {}
    end

    def [](ident)
      @hash[ident]
    end

    # Sets special bin class table by identifier.
    def set_special_bin(special_bin)
      @special_bin = special_bin
    end

    def push(tuple)
      key = bin_key(tuple)
      prepare_table(key)
      @mutex.synchronize {@hash[key].add(tuple)}
    end

    def delete(tuple)
      key = bin_key(tuple)
      bin = @mutex.synchronize {@hash[key]}
      return nil unless bin
      @mutex.synchronize {bin.delete(tuple)}
      @mutex.synchronize {@hash.delete(key) if bin.empty?}
      return tuple
    end

    def prepare_table(key)
      unless @mutex.synchronize {@hash[key]}
        @mutex.synchronize {@hash[key] = bin_class(key).new}
      end
    end

    def bin_class(key)
      return TupleBin unless @special_bin
      return @special_bin.has_key?(key) ? @special_bin[key] : TupleBin
    end

    alias :orig_find :find
    alias :orig_find_all :find_all

    public

    # Returns all tuples in the bag.
    def all_tuples
      @mutex.synchronize{@hash.values}.map{|bin| bin.elements}.flatten
    end

    def find(template)
      key = bin_key(template)
      if @special_bin[key]
        prepare_table(key)
        @mutex.synchronize{@hash[key]}.find(template) do |tuple|
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
        @mutex.synchronize{@hash[key]}.find_all(template) do |tuple|
          tuple.alive? && template.match(tuple)
        end
      else
        orig_find_all(template)
      end
    end

    def find_template(tuple)
      @enum.find do |template|
        template.alive? && template.match(tuple)
      end
    end

    def delete_unless_alive
      deleted = []
      @mutex.synchronize do
        @hash.each do |key, bin|
          bin.delete_if do |tuple|
            if tuple.alive?
              false
            else
              deleted.push(tuple)
              true
            end
          end
        end
      end
      deleted
    end

    def task_size
      @mutex.synchronize{@hash[:task]}.size rescue 0
    end

    def working_size
      @mutex.synchronize{@hash[:working]}.size rescue 0
    end

    def finished_size
      @mutex.synchronize{@hash[:finished]}.size rescue 0
    end

    def data_size
      @mutex.synchronize{@hash[:data]}.size rescue 0
    end

    private

    def each_entry(&blk)
      @mutex.synchronize do
        @hash.each do |k, v|
          v.each(&blk)
        end
      end
    end
  end

  class TupleSpace
    attr_reader :bag
    attr_reader :take_waiter
    attr_reader :read_waiter

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
      @mutex = Mutex.new
    end

    def write(tuple, *args)
      tuple.timestamp = Time.now
      real_write(tuple, *args)
    end

    def move(port, tuple, sec=nil)
      real_move(port, tuple, sec)
    end

    def read(tuple, sec=nil)
      shift_tuple(real_read(tuple, sec))
    end

    def read_all(tuple)
      real_read_all(tuple).map do |res|
        shift_tuple(res)
      end
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
        @mutex.synchronize{@bag.all_tuples}.map{|tuple| tuple.value}
      when :read_waiter
        @mutex.synchronize{@read_waiter.all_tuples}.map{|tuple| tuple.value}
      when :take_waiter
        @mutex.synchronize{@take_waiter.all_tuples}.map{|tuple| tuple.value}
      end
    end

    # @note
    #   mutex version of +notify+
    def notify(event, tuple, sec=nil)
      template = NotifyTemplateEntry.new(self, event, tuple, sec)
      @mutex.synchronize {@notify_waiter.push(template)}
      template
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

    # @note
    #   mutex version of +write+
    def real_write(tuple, sec=nil)
      entry = create_entry(tuple, sec)
      if entry.expired?
        # why only read_waiter???
        @mutex.synchronize{@read_waiter.find_all_template(entry)}.each do |template|
          template.read(tuple)
        end
        notify_event('write', entry.value)
        notify_event('delete', entry.value)
      else
        # push to bag
        @mutex.synchronize do
          @bag.push(entry)
        end
        # start keeper
        start_keeper if entry.expires
        # send tuple to all matched waiters in read waiter list
        @mutex.synchronize do
          @read_waiter.find_all_template(entry).each do |template|
            template.read(tuple)
          end
        end
        # send tuple to one of matched waiters in take waiter list
        @mutex.synchronize do
          if template = @take_waiter.find_template(entry)
            template.signal
          end
        end
        notify_event('write', entry.value)
      end
      entry
    end

    # @note
    #   mutex version of +move+
    def real_move(port, tuple, sec=nil)
      template = WaitTemplateEntry.new(self, tuple, sec)
      yield(template) if block_given?

      if entry = @mutex.synchronize {@bag.find(template)}
        port.push(entry.value) if port
        @mutex.synchronize {@bag.delete(entry)}
        notify_event('take', entry.value)
        template.finished = true
        return entry.value
      end
      raise RequestExpiredError if template.expired?

      begin
        @mutex.synchronize {@take_waiter.push(template)}
        start_keeper if template.expires
        while true
          raise RequestCanceledError if template.canceled?
          raise RequestExpiredError if template.expired?
          if entry = @mutex.synchronize {@bag.find(template)}
            port.push(entry.value) if port
            @mutex.synchronize {@bag.delete(entry)}
            notify_event('take', entry.value)
            template.finished = true
            @mutex.synchronize do
              @take_waiter.delete(template)
            end
            return entry.value
          end
          Thread.current[:WaitTemplate] = template
          template.wait
          Thread.current[:WaitTemplate] = nil
        end
      ensure
        @mutex.synchronize {@take_waiter.delete(template)}
      end
    end

    # @note
    #   mutex version of +read+
    def real_read(tuple, sec=nil)
      template = WaitTemplateEntry.new(self, tuple, sec)
      yield(template) if block_given?

      entry = @mutex.synchronize {@bag.find(template)}
      return entry.value if entry
      raise RequestExpiredError if template.expired?

      begin
        @mutex.synchronize {@read_waiter.push(template)}
        start_keeper if template.expires
        template.wait
        raise RequestCanceledError if template.canceled?
        raise RequestExpiredError if template.expired?
        return template.found
      ensure
        @mutex.synchronize {@read_waiter.delete(template)}
      end
    end

    # @note
    #   mutex version of +read_all+
    def real_read_all(tuple)
      template = WaitTemplateEntry.new(self, tuple, nil)
      entry = @mutex.synchronize {@bag.find_all(template)}
      entry.collect {|e| e.value}
    end

    # @note
    #   mutex version of +keep_clean+
    def keep_clean
      @mutex.synchronize{@read_waiter.delete_unless_alive}.each do |e|
        e.signal
      end
      @mutex.synchronize{@take_waiter.delete_unless_alive}.each do |e|
        e.signal
      end
      @mutex.synchronize{@notify_waiter.delete_unless_alive}.each do |e|
        e.notify(['close'])
      end
      @mutex.synchronize{@bag.delete_unless_alive}.each do |e|
        notify_event('delete', e.value)
      end
    end

    # @note
    #   mutex version of +start_keeper+
    def start_keeper
      return if @keeper && @keeper.alive?
      @keeper = Thread.new do
        while true
          sleep(@period)
          break unless need_keeper?
          keep_clean
        end
      end
    end

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
