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
    # class TupleBin
    #   def add(tuple)
    #     @bin.push(tuple) unless check_cancel(tuple)
    #   end

    #   def check_cancel(tuple)
    #     return false unless tuple.class == TupleEntry
    #     return false unless tuple.value.first == :task
    #     Pione.show tuple.value.inspect
    #     return @bin.include?(tuple)
    #   end
    # end

    # alias :orig_bin_key :bin_key
    # def bin_key(tuple)
    #   case tuple[0]
    #   when :task
    #     return "task_%s" % tuple[5]
    #   else
    #     return orig_bin_key(tuple)
    #   end
    # end
  end
end
