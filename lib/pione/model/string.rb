module Pione
  module Model
    # PioneString is a string value in PIONE system.
    class PioneString < BasicModel
      set_pione_model_type TypeString
      attr_reader :value

      # Create a string with the value.
      #
      # @param value [String]
      #   string value
      def initialize(value)
        @value = value
        super()
      end

      # Evaluate the object with the variable table.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        self.class.new(vtable.expand(@value))
      end

      # Return true if the value includes variables.
      #
      # @return [Boolean]
      #   true if the value includes variables
      def include_variable?
        VariableTable.check_include_variable(@value)
      end

      # Return a sequence that contains self.
      #
      # @return [PioneStringSequence]
      #   a sequence
      def to_seq
        PioneStringSequence.new([self])
      end

      # @api private
      def task_id_string
        "String<#{@value}>"
      end

      # @api private
      def textize
        "\"%s\"" % [@value]
      end

      # Return ruby's value.
      #
      # @return [String]
      #   the value in ruby
      def to_ruby
        return @value
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @value == other.value
      end

      alias :eql? :"=="

      # @api private
      def hash
        @value.hash
      end

      def inspect
        '#<PioneString "%s">' % @value
      end
    end

    class PioneStringSequence < BasicSequence
      set_pione_model_type TypeString
      set_element_class PioneString

      def value
        @value ||= @elements.map{|elt| elt.value}.join
      end

      def set_annotation_type(type)
        self.class.new(@elements, @attribute.merge(annotation_type: type))
      end
    end

    TypeString.instance_eval do
      define_pione_method("+", [TypeString], TypeString) do |rec, other|
        raise Model::AttributeError.new(other.attribute) unless rec.attribute == other.attribute
        rec.elements.map do |rec_elt|
          other.elements.map do |other_elt|
            PioneString.new(rec_elt.value + other_elt.value)
          end
        end.flatten.tap {|x| break PioneStringSequence.new(x, rec.attribute)}
      end

      define_pione_method("as_string", [], TypeString) do |rec|
        rec
      end

      define_pione_method("as_integer", [], TypeInteger) do |rec|
        sequential_map1(TypeInteger, rec) do |elt|
          elt.value.to_i
        end
      end

      define_pione_method("as_float", [], TypeFloat) do |rec|
        sequential_map1(TypeFloat, rec) do |elt|
          elt.value.to_f
        end
      end

      define_pione_method("as_data_expr", [], TypeDataExpr) do |rec|
        DataExpr.new(rec.value)
      end

      define_pione_method("count", [], TypeInteger) do |rec|
        rec.elements.map do |elt|
          PioneIntegerSequence.new([PioneInteger.new(elt.value.size)])
        end.tap {|x| break PioneIntegerSequence.new(x)}
      end

      define_pione_method("include?", [TypeString], TypeBoolean) do |rec, target|
        sequential_map2(TypeBoolean, rec, target) do |rec_elt, target_elt|
          rec_elt.value.include?(target_elt.value)
        end
      end

      define_pione_method("substring",
        [TypeInteger, TypeInteger],
        TypeString) do |rec, nth, len|
        sequential_map2(TypeString, nth, len) do |nth_elt, len_elt|
          rec.value[nth_elt.value-1, len_elt.value]
        end
      end

      define_pione_method("insert", [TypeInteger, TypeString], TypeString) do |rec, pos, other|
        sequential_map3(TypeString, rec, pos, other) do |rec_elt, pos_elt, other_elt|
          rec_elt.value.clone.insert(pos_elt.value-1, other_elt.value)
        end
      end

      define_pione_method("author", [], TypeString) do |rec|
        rec.set_annotation_type(:author)
      end
    end
  end
end

# String extention for PIONE system.
class String
  # Return PIONE's value.
  #
  # @return [PioneString]
  #   PIONE's value
  def to_pione
    PioneString.new(self)
  end
end
